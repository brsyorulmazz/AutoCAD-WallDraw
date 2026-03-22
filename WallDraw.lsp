;;; ===========================================================================
;;; WallDraw - Advanced Architectural Wall Tool
;;; Version: 1.0.0
;;; Author: Barış Yorulmaz (METU Architecture)
;;; GitHub: https://github.com/brsyorulmazz/AutoCAD-WallDraw
;;; License: MIT
;;; ===========================================================================

(defun c:WALLDRAW ( / kwd tmp pt1 ent_old ent obj pt_start pt_end param_start param_end first_deriv_start first_deriv_end ang_start ang_end ang_start_L ang_start_R ang_end_L ang_end_R p_start_L p_start_R p_end_L p_end_R ent_L ent_R line1 line2 is_closed osmode_old cmdecho_old peditaccept_old)
  
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
  
  ;; 3. Drafting Phase with Persistent Reminder
  (command "_.PLINE" "_non" pt1)
  (while (> (getvar "CMDACTIVE") 0)
    ;; This will print the reminder to the command line after every input/click
    (princ "\nWallDraw: [A]rc mode | [L]ine mode | [C]lose loop | Pick next point: ")
    (command "\\")
  )
  (setq ent (entlast))

  ;; 4. Processing & Geometry
  (if (and ent (not (equal ent ent_old)) (= (cdr (assoc 0 (entget ent))) "LWPOLYLINE"))
    (progn
      (setvar "CMDECHO" 0)
      (setvar "OSMODE" 0)

      (setq obj (vlax-ename->vla-object ent))
      (setq pt_start (vlax-curve-getStartPoint obj))
      (setq pt_end (vlax-curve-getEndPoint obj))

      ;; Closed Loop Check
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

      ;; Apply Endcap Extension
      (if (and (not is_closed) (> *wd-cap* 0.0))
        (progn
          (command "_.LENGTHEN" "_Delta" *wd-cap* (list ent pt_start) "")
          (command "_.LENGTHEN" "_Delta" *wd-cap* (list ent pt_end) "")
          (setq obj (vlax-ename->vla-object ent))
          (setq pt_start (vlax-curve-getStartPoint obj))
          (setq pt_end (vlax-curve-getEndPoint obj))
        )
      )

      ;; Calculate Angles for Endcaps
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

      ;; 5. Justification & Offset
      (cond
        ((= *wd-just* "Center")
         (setq p_start_L (polar pt_start ang_start_L (/ *wd-thick* 2.0)))
         (setq p_start_R (polar pt_start ang_start_R (/ *wd-thick* 2.0)))
         (setq p_end_L (polar pt_end ang_end_L (/ *wd-thick* 2.0)))
         (setq p_end_R (polar pt_end ang_end_R (/ *wd-thick* 2.0)))
         (command "_.OFFSET" (/ *wd-thick* 2.0) ent "_non" p_start_L "") (setq ent_L (entlast))
         (command "_.OFFSET" (/ *wd-thick* 2.0) ent "_non" p_start_R "") (setq ent_R (entlast))
        )
        ((= *wd-just* "Left")
         (setq p_start_L pt_start)
         (setq p_start_R (polar pt_start ang_start_R *wd-thick*))
         (setq p_end_L pt_end)
         (setq p_end_R (polar pt_end ang_end_R *wd-thick*))
         (command "_.COPY" ent "" '(0 0 0) '(0 0 0)) (setq ent_L (entlast))
         (command "_.OFFSET" *wd-thick* ent "_non" p_start_R "") (setq ent_R (entlast))
        )
        ((= *wd-just* "Right")
         (setq p_start_L (polar pt_start ang_start_L *wd-thick*))
         (setq p_start_R pt_start)
         (setq p_end_L (polar pt_end ang_end_L *wd-thick*))
         (setq p_end_R pt_end)
         (command "_.OFFSET" *wd-thick* ent "_non" p_start_L "") (setq ent_L (entlast))
         (command "_.COPY" ent "" '(0 0 0) '(0 0 0)) (setq ent_R (entlast))
        )
      )

      ;; 6. Endcaps & Joining
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
    (princ "\nCommand cancelled.")
  )

  (setvar "OSMODE" osmode_old)
  (setvar "CMDECHO" cmdecho_old)
  (princ)
)
