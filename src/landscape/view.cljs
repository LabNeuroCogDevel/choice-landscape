(ns landscape.view
  (:require
   [landscape.sprite :as sprite]
   [landscape.utils :as utils]
   [landscape.model :as model]
   [landscape.settings :refer [current-settings]]
   [landscape.instruction :as instruction]
   [landscape.model.survey :as survey]
   [landscape.key :as key]
   [cljsjs.react]
   [cljsjs.react.dom]
   [sablono.core :as sab :include-macros true :refer-macros [html]]
   [debux.cs.core :as d :refer-macros [clog clogn dbg dbgn dbg-last break]]
   [cljs.core.async :refer [<! chan sliding-buffer put! close! timeout]])
  (:require-macros [devcards.core :refer [defcard]]))

;;
(def ^:export DEBUG
  "show phase edn? display will no longer be pixel perfect
  use in javscript console like: landscape.view.DEBUG = true"
  false)

(def CHANGE-DOM-ID "id of element where updates will go"
  "main-container")
(defn change-dom
  "replace body w/ sab/html element"
  [reactdom]
    (let [node (.getElementById js/document CHANGE-DOM-ID)]
      (.render js/ReactDOM reactdom node)))

(defn position-at
  [{:keys [x y] :as pos} inner]
  (html [:div.abs {:style {:position "absolute"
                           :transform (str "translate(" x "px, " y "px")}}
         inner]))


;; scene components
(defn water-fill
  "show progress with growing image. scale by FILL"
  [fill]
  (let [img (case (:vis-type @current-settings)
              :mountain "imgs/money_pool.png"
              "imgs/water.png"
              )]
    (html [:img#water {:src img :style {:transform (str "scale(" (/ fill 100) ")")}}])))

(defn water [state]
  (let [fill (get-in state [:water :scale])]
    (water-fill fill)))

;; TODO: should this be in phase.cljs?
(defn photodiode-color
  "define colors for each phase.
  Paging between instructions can be used to test hardware (color based on instruction idx)"
  [{:keys [name] :as phase}]
  (cond 
     (= name :waiting)     "white"
     (= name :chose)       "#333"
     (= name :iti)         "#666"
     (= name :feedback)    "black"
     ;; switch every other instruction
     (= name :instruction) (if (even? (or 0 (:idx phase))) "#ccc" "#333")
     (= name :survey)      "#999"
     :else                 "black"))

(defn photodiode
  "display block to position photodiode over. for percision timing"
  ([state]
   (photodiode state [0 0]))
  ([{:keys [phase] :as state} pos]
     (when (:use-photodiode? state)
       (position-at pos (html [:div#photodiode {:style {:background-color (photodiode-color phase)}}])))))

(defn progress-bar
  "show how far along we are in the task."
  [{:keys [trial well-list water] :as  state}]
  (let [ntrials (count well-list)
        score (/ (:score water) ntrials)
        progress (/ trial ntrials)
        vis-class (-> @current-settings :vis-type name)]
    (position-at (:bar-pos @current-settings)
                 (html [:div#fullbar {:class vis-class}
                        [:div#progressbar_trials {:class vis-class
                                                  :style {:height "100%" :width (str (* progress 100) "%")}}]
                        ;[:div#progressbar_score  {:style {:height "49%" :width (str (* score 100) "%")}}]
]))))

(defn bucket []
  (let [imgsrc (case (get @current-settings :vis-type)
                           :mountain "imgs/axe.png"
                           "imgs/bucket.png")]
              (html [:img {:src imgsrc :style {:transform "translate(20px, 30px)"}}])))

(defn well-or-mine
  "what sprite to use based on the board setting. default to well"
  [] (case (get @current-settings :vis-type)
       :mountain sprite/mine
       sprite/well))

(defn well-show "draw single well. maybe animate sprite"
        [{:keys [time-cur] :as state}
         {:keys [active-at score open] :as well}]
        (let [tstep (sprite/get-step time-cur active-at (:dur-ms sprite/well))
              css (sprite/css (well-or-mine) tstep)
              ;; if not score, move bg down to get the failed well offset
              v-offset (if score {}
                           {:background-position-y
                            (str "-" (:height sprite/well) "px")}
                           )]
          (html [:div.well {:style (merge css v-offset)}
                 (if open (bucket))])))


(defn well-side
  "side is :left :up :right"
  [{:keys [wells] :as state} side]
  (position-at (get-in wells [side :pos])
               (html [:div {:on-click #(key/sim-key side)}
                      (well-show state (side wells))])))

(defn well-show-all
  "3 wells not all equadistant. sprite for animate"
  [{:keys [wells] :as state}]
  (html [:div.wells
         (well-side state :left)
         (well-side state :up)
         (well-side state :right)]))

(defn button-keys [] (html [:div.bottom
                               [:button {:on-click #(key/sim-key :left)
                                         :class "arrow"}
                                [:img {:src "imgs/arrow_l.png"}]]
                               [:button {:on-click #(key/sim-key :up)
                                         :class "arrow"}
                                [:img {:src "imgs/arrow_l.png"
                                       :class "rot_up"}]]
                               [:button {:on-click #(key/sim-key :down)
                                         :class "arrow"}
                                [:img {:src "imgs/arrow_l.png"
                                       :class "rot_down"}]]
                               [:button {:on-click #(key/sim-key :right)
                                         :class "arrow"}
                                [:img {:src "imgs/arrow_l.png"
                                       :class "rot_lr"}]]]))
(defn instruction-view [{:keys [phase] :as state}]
        (let [idx (or (:idx phase) 0)
              instr (get instruction/INSTRUCTION idx)
              pos-fn (or (:pos instr) (fn[_] {:x 0 :y 0}))]
          (position-at (pos-fn state)
                       (html [:div#instruction
                              [:div.top (str (inc idx) "/" (count instruction/INSTRUCTION))]
                              [:br]
                              ((:text instr) state)
                              [:br]
                              (button-keys)]))))
(defn survey-view [{:keys [phase] :as state}]
  (let [qi (or  (:qi phase) 0)
        ci (or  (:ci phase) 0)
        quest (get-in survey/SURVEYS [qi :q])
        choices (get-in survey/SURVEYS [qi :answers])
        cur-choice (if (count choices) (nth choices ci) "ALL DONE")
        ]
    (position-at {:x 100 :y 10}
                 (html [:div#insturctions
                   [:div#instruction
                    [:div.top (str (inc qi) "/" (count survey/SURVEYS))]
                    [:h3 quest]
                    [:ul#pick (mapv
                               #(html [:li { ;; :id  TODO
                                            :class
                                            (if (= cur-choice %) "picked" "ignored")}  %])
                               choices)]
                    (button-keys)]]))))

(defn done-view [state]
  (html [:div#instruction
          [:h1 "Great Job!"] [:h3 "You filled the pond!"]
          [:br] "Thank you for contributing to our research!"
          [:br] "Your responses have been recorded. You can close this page."
          [:br]]))

(defn display-state
  "html to render for display. updates for any change in display"
  [{:keys [phase avatar] :as state}]
  (let [avatar-pos (get-in state [:avatar :pos])
        vis-class (-> @current-settings :vis-type name)]
    (sab/html
     [:div#background {:class vis-class}
      (if DEBUG [:div {:style {:color "white"}} (str phase)])
      (water state)
      (well-show-all state)
      ;; NB. this conditional is only for display
      ;; we're waiting regardless of whats shown
      ;; dont want to rework the logic to be agnostic to actual phase
      ;; :show-cross exists only in instruction phase
      (if (or (get phase :show-cross)
              (= :iti (:name phase)))
        ;; cross does not get centered well. off by a few pixels
        (position-at (update avatar-pos :x #(+ % 5))
                     (html [:div.iti "+"]))
        (position-at avatar-pos (sprite/avatar-disp state avatar)))

      (progress-bar state)

      ;; instructions on top so covers anything else
      ;; -- maybe we want them under?
      (case (:name phase)
        :instruction  (instruction-view state)
        :survey (survey-view state)
        :forum (survey/view-questions)
        :done (done-view state)
        nil)

      ;; and very top add photodiode square (when anchor portion of url calls for it)
      (photodiode state)])))



;; debug/devcards
(defcard well-no-and-score
  "well animation by steps. should animate with js/animate"
  (fn [state owner]
    (utils/wrap-state state [:div
                             (well-show @state (assoc @state :score nil))
                             (well-show @state (assoc @state :score 1))]))
  {:time-cur 100 :active-at 100 :open true})

(defcard mine-sprite
  "mine animation by steps"
  (fn [state owner]
    (with-redefs [current-settings (atom (assoc @current-settings :vis-type :mountain))]
      (utils/wrap-state state [:div
                                 (well-show @state (assoc  @state :score nil))
                                (well-show @state (assoc  @state :score 1))])
        ))
  {:time-cur 100 :active-at 100 :open true})

(defcard avatar
  "step through avatar"
  (fn [state owner]
    (html [:div
           (utils/wrap-state state (sprite/avatar-disp @state @state))
           [:button {:on-click (fn [] (swap! state assoc :direction :left))} "left"]
           [:button {:on-click (fn [] (swap! state assoc :direction :right))} "right"]
           [:button {:on-click (fn [] (swap! state assoc :direction :up))} "up"]
           [:button {:on-click (fn [] (swap! state assoc :direction :down))} "down"]
           [:br]
           [:select {:on-change #(swap! state assoc :sprite-picked (-> % .-target .-value keyword))}
            (map #(html [:option { :value (name %)} (name %)]) (keys sprite/avatars))]
           [:br]
           (str @state)
           ]))
  {:time-cur 100 :active-at 100 :direction :left :sprite-picked :astro})

(defcard photodiode-card
  (fn [state owner] (html
           [:div
            [:button {:on-click (fn [] (swap! state assoc-in [:phase :name] :chose))} "chose"]
            [:button {:on-click (fn [] (swap! state assoc-in [:phase :name] :waiting))} "waiting"]
            [:button {:on-click (fn [] (swap! state assoc-in [:phase :name] :feedback))} "feedback"]
            [:button {:on-click (fn [] (swap! state assoc-in [:phase :name] :iti))} "iti"]
            (photodiode @state)]))
  {:phase {:name :chose} :use-photodiode? true})
