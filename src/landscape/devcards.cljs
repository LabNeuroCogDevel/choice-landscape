(ns landscape.devcards
  (:require
   [devcards.core]
   [landscape.utils :as utils]
   [landscape.view :as view]
   [landscape.model.survey :as survey]
   [landscape.model :as model]
   [landscape.model.avatar :as avatar]
   [landscape.model.points :as points]
   [sablono.core :as sab :include-macros true :refer-macros [html]])
  (:require-macros [devcards.core :refer [defcard]]))
(enable-console-print!)

(defcard move
  "positioning to destition"
  (fn [state own]
     (html [:div
            (view/position-at (-> @state :avatar :pos) (html [:div "*"]))
            [:br]
            (str @state)
            [:br]
            [:button {:on-click (fn[] (reset!
                                      state
                                      (-> @state 
                                          avatar/move-avatar
                                          (update-in [:time-cur] #(+ 100 %)))))}
             "inc" ]
            [:button {:on-click (fn[](swap! state assoc-in [:avatar :pos :x] 0))}
             "reset"]]))
    
  {:avatar  {:pos {:x 0 :y 0}
             :destination {:x 100 :y 0}
             :active-at 0
             :last-move 0}
   :time-cur 0})


;; (def water-atom-devcard
;;   (let [state (atom {:water {:level 5 :active-at 10} :time-cur 10})]
;;     (js/setInterval (fn[] (swap! state update :time-cur inc) ;; (reset! state
;;                          ;;          (-> @state
;;                          ;;              (update :time-cur #(mod (inc %) 2000))
;;                          ;;              (model/water-pulse)))
;;                       ))))

(defcard water-pulse
  "run through osilating water pulsing"
  (fn[state o]
       (html [:div (view/water @state)
           [:br]
           [:p (str @state)]
           [:button {:on-click (fn [_] (swap! state (fn[_] {:water {:level 5 :active-at 10} :time-cur 0} )))} "reset"]]
          ))
  {:water {:level 5 :active-at 10} :time-cur 10})

;; moving scoring point around
(defcard single-point-float-card
"what one point looks like"
  (let [point (points/new-point-floating 1 (points/->pos 10 10) (points/->pos 0 0))]
    (landscape.view/show-point-floating point)))
(defcard points-float-card
"score a point, float up"
  (let [state
        {:points-floating
         [(points/new-point-floating 1 (points/->pos 10 0) (points/->pos 0 0))
          (points/new-point-floating 2 (points/->pos 40 10) (points/->pos 0 0))]}]
    (landscape.view/show-points-floating state)))

;; moved from survey to avoid warnings
(defcard survey-forum
  "what does the survey look like. TODO: working forum"
  (fn [fa o]
    (html [:div (survey/view-questions)
           [:b (:age @fa)]
           [:button {:onclick (fn [_](reset! fa @survey/forum-atom))} "reset"]])
    )
  (atom {:age 10 :understand 0 :done false}))
;; help from 
;; https://github.com/onetom/clj-figwheel-main-devcards
;; https://github.com/bhauman/devcards/issues/148
;; look to
;; http://localhost:9500/figwheel-extra-main/cards  ; auto
;; http://localhost:9500/cards.html                 ; manual
;(defcard example-card "hi")
(devcards.core/start-devcard-ui!)
