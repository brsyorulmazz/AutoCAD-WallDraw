;;; ===========================================================================
;;; WallDraw - Advanced Architectural Wall Tool
;;; Version: 1.0.4
;;; Author: Barış Yorulmaz (METU Architecture)
;;; GitHub: https://github.com/brsyorulmazz/AutoCAD-WallDraw
;;; License: MIT
;;; ===========================================================================

(defun c:WALLDRAW ( / kwd tmp pt1 ent_old ent obj pt_start pt_end param_start param_end first_deriv_start first_deriv_end ang_start ang_end ang_start_L ang_start_R ang_end_L ang_end_R p_start_L p_start_R p_end_L p_end_R ent_L ent_R line1 line2 is_closed osmode_old cmdecho_old peditaccept_old elist new_elist last_pt pt_count i item j err_flag last_e)
  
  (vl-load-com)

  ;; 1. Default Settings (Stored in memory)
  (if (null *wd-thick*) (setq *wd-thick* 20.0))
  (if (null *wd-cap*)   (setq *wd-cap* 0.0))
  (if (null *wd-just*)  (setq *wd-just* "Center")) ;; Options: Left, Center, Right

  ;; 2. Dynamic Command Menu
  (setq pt1 nil)
  (while (null pt1)
    (initget "Thickness Endcap Justification") 
    (setq kwd (getpoint (strcat "\nSpecify start point or [Thickness/Endcap/Justification] <T=" (rtos *wd-thick* 2 2) ", E=" (rtos *wd-cap* 2 2) ", J=" *wd-just* ">: ")))
    
    (cond
      ((= kwd "Thickness")
       (if (setq tmp (getreal (strcat "\nEnter new wall thickness <" (rtos *wd-thick* 2 2) ">: "))) (setq *wd-thick* tmp)))
      ((= kwd "Endcap")
       (if (setq tmp (getreal (strcat "\nEnter endcap extension length <" (rtos *wd-cap* 2 2) ">: "))) (setq *wd-cap* tmp)))
      ((= kwd "Justification")
       (initget "Left Center Right")
       (if (setq tmp (getkword (strcat "\nChoose justification [Left/Center/Right] <" *wd-just* ">: "))) (setq *wd-just* tmp)))
      ((= (type kwd) 'LIST) (setq pt1 kwd))
      (t (exit)) 
    )
  )

  (setq ent_old (entlast))
  (setq osmode_old (getvar "OSMODE"))
  (setq cmdecho_old (getvar "CMDECHO"))
  
  ;; 3. Drafting Phase
  (command "_.PLINE" "_non" pt1)
  (while (> (getvar "CMDACTIVE") 0)
    (princ "\nWallDraw: [A]rc mode | [L]ine mode | [C]lose loop | Pick next point: ")
    (command "\\")
  )
  (setq ent (entlast))

  ;; 4. Processing & Geometry
  (if (and ent (not (equal ent ent_old)) (= (cdr (assoc 0 (entget ent))) "LWPOLYLINE"))
    (progn
      
      ;; 4.1 ADVANCED Micro-Jitter Cleanup
      (setq elist (entget ent))
      (setq new_elist nil)
      (setq last_pt nil)
      (setq pt_count 0)
      (setq i 0)
      
      (while (< i (length elist))
        (setq item (nth i elist))
        (if (= (car item) 10)
          (progn
            (setq p1 (cdr item))
            (if (or (null last_pt) (> (distance p1 last_pt) 0.05))
              (progn
                (setq new_elist (append new_elist (list item)))
                (setq last_pt p1)
                (setq pt_count (1+ pt_count))
                (setq j (1+ i))
                (while (and (< j (length elist)) (member (car (nth j elist)) '(40 41 42)))
                  (setq new_elist (append new_elist (list (nth j elist))))
                  (setq j (1+ j))
                )
                (setq i (1- j))
              )
              (progn
                (setq j (1+ i))
                (while (and (< j (length elist)) (member (car (nth j elist)) '(40 41 42)))
                  (setq j (1+ j))
                )
                (setq i (1- j))
              )
            )
          )
          (if (not (member (car item) '(40 41 42)))
            (setq new_elist (append new_elist (list item)))
          )
        )
        (setq i (1+ i))
      )
      
      ;; *CRITICAL FIX*: Update vertex count (DXF 90) before modifying entity
      (if (assoc 90 new_elist)
        (setq new_elist (subst (cons 90 pt_count) (assoc 90 new_elist) new_elist))
      )
      
      (entmod new_elist)
      (entupd ent)

      (if (>= pt_count 2)
        (progn
          (setvar "CMDECHO" 0)
          (setvar "OSMODE" 0)

          (setq obj (vlax-ename->vla-object ent))
          (setq pt_start (vlax-curve-getStartPoint obj))
          (setq pt_end (vlax-curve-getEndPoint obj))

          (setq is_closed nil)
          (if (or (= (logand (cdr (assoc 70 (entget ent))) 1) 1) 
                  (< (distance pt_start pt_end) 0.001))           
            (progn
              (setq is_closed t)
              (if (/= (logand (cdr (assoc 70 (entget ent))) 1) 1)
                (vla-put-closed obj :vlax-true)
              )
            )
          )

          (if (and (not is_closed) (> *wd-cap* 0.0))
            (progn
              (command "_.LENGTHEN" "_Delta" *wd-cap* (list ent pt_start) "")
              (command "_.LENGTHEN" "_Delta" *wd-cap* (list ent pt_end) "")
              (setq obj (vlax-ename->vla-object ent))
              (setq pt_start (vlax-curve-getStartPoint obj))
              (setq pt_end (vlax-curve-getEndPoint obj))
            )
          )

          (setq param_start (vlax-curve-getStartParam obj))
          (setq first_deriv_start (vlax-curve-getFirstDeriv obj param_start))
          (setq ang_start (angle '(0 0 0) first_deriv_start))

          (setq param_end (vlax-curve-getEndParam obj))
          (setq first_deriv_end (vlax-curve-getFirstDeriv obj param_end))
          (setq ang_end (angle '(0 0 0) first_deriv_end))

          (setq ang_start_L (+ ang_start (/ pi 2.0)))
          (setq ang_start_R (- ang_start (/ pi 2.0)))
          (setq ang_end_L (+ ang_end (/ pi 2.0)))
          (setq ang_end_R (- ang_end (/ pi 2.0)))

          (setq err_flag nil)
          
          (cond
            ((= *wd-just* "Center")
             (setq p_start_L (polar pt_start ang_start_L (/ *wd-thick* 2.0)))
             (setq p_start_R (polar pt_start ang_start_R (/ *wd-thick* 2.0)))
             (setq p_end_L (polar pt_end ang_end_L (/ *wd-thick* 2.0)))
             (setq p_end_R (polar pt_end ang_end_R (/ *wd-thick* 2.0)))
             
             (setq last_e (entlast))
             (vl-cmdf "_.OFFSET" (/ *wd-thick* 2.0) ent "_non" p_start_L "")
             (if (equal last_e (entlast)) (setq err_flag t) (setq ent_L (entlast)))
             
             (setq last_e (entlast))
             (vl-cmdf "_.OFFSET" (/ *wd-thick* 2.0) ent "_non" p_start_R "")
             (if (equal last_e (entlast)) (setq err_flag t) (setq ent_R (entlast)))
            )
            ((= *wd-just* "Left")
             (setq p_start_L pt_start)
             (setq p_start_R (polar pt_start ang_start_R *wd-thick*))
             (setq p_end_L pt_end)
             (setq p_end_R (polar pt_end ang_end_R *wd-thick*))
             
             (command "_.COPY" ent "" '(0 0 0) '(0 0 0)) (setq ent_L (entlast))
             (setq last_e (entlast))
             (vl-cmdf "_.OFFSET" *wd-thick* ent "_non" p_start_R "")
             (if (equal last_e (entlast)) (setq err_flag t) (setq ent_R (entlast)))
            )
            ((= *wd-just* "Right")
             (setq p_start_L (polar pt_start ang_start_L *wd-thick*))
             (setq p_start_R pt_start)
             (setq p_end_L (polar pt_end ang_end_L *wd-thick*))
             (setq p_end_R pt_end)
             
             (setq last_e (entlast))
             (vl-cmdf "_.OFFSET" *wd-thick* ent "_non" p_start_L "")
             (if (equal last_e (entlast)) (setq err_flag t) (setq ent_L (entlast)))
             (command "_.COPY" ent "" '(0 0 0) '(0 0 0)) (setq ent_R (entlast))
            )
          )

          (if err_flag
            (progn
              (if ent_L (entdel ent_L))
              (if ent_R (entdel ent_R))
              (princ "\nWallDraw: Geometry too complex (backtracking). Safety abort triggered. Original line kept.")
            )
            (progn
              (if is_closed
                (progn
                  (entdel ent) 
                  (princ "\nClosed wall loop created successfully.")
                )
                (progn
                  (command "_.LINE" "_non" p_start_L "_non" p_start_R "") (setq line1 (entlast))
                  (command "_.LINE" "_non" p_end_L "_non" p_end_R "") (setq line2 (entlast))

                  (setq peditaccept_old (getvar "PEDITACCEPT"))
                  (setvar "PEDITACCEPT" 1)
                  (command "_.PEDIT" "_M" ent_L ent_R line1 line2 "" "_J" "0.05" "")
                  (setvar "PEDITACCEPT" peditaccept_old)

                  (entdel ent) 
                  (princ "\nWall created successfully. Use 'TRIM' for intersections.")
                )
              )
            )
          )
        )
        (progn
          (entdel ent)
          (princ "\nWallDraw: Polyline invalid or too short. Command cancelled.")
        )
      )
    )
    (princ "\nCommand cancelled.")
  )

  (setvar "OSMODE" osmode_old)
  (setvar "CMDECHO" cmdecho_old)
  (princ)
)
