#!/usr/bin/env Rscript
# 20220412FC - init copied in (WF)
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyr, dplyr, ggplot2, mgcv, mgcViz, tidyquant,cowplot)
source('read_raw.R') # read_raw()
theme_set(theme_cowplot())
select <- dplyr::select

read_summary <- function() read.csv("lab.summary.csv", comment.char="")


rawdata <<- NULL
task_summary_data <<- NULL
update_data  <- function(runMake=FALSE){
   if(runMake) system("make all")
   rawdata <<- read_raw("lab.data.tsv")
   task_summary_data <<- read_summary()
}

# modifies globals rawdata and task_summary_data
update_data(runMake=FALSE)

MAXTRIALS <- max(rawdata$trial) # 215 (as of 20220413)

# probably could do with as.factor and keep labels or use case_when.
# blocktype needs additional attention. have more names
# numbers only needed to compare to farWell and initHigh.
# can maybe save some effort and use string values directly?
# blocknum only used to display block rectangles
subset_data <- function(rawdata, date_range, versions, task_selection, blockseq_select) {
  # narrow data to just more recent versions
  #VER_REGEX <- 'v9_|v10_'
  #grepl(VER_REGEX,ver)
  # date_range = structure(c(1646088374.05442, 1649727627.27253), class = c("POSIXct", "POSIXt"), tzone = "UTC")

  sub <- rawdata %>%
     filter(vdate >= date_range[1],
            vdate <= date_range[2],
            ver %in% versions,
            task %in% task_selection,
            blockseq %in% blockseq_select)
}

#### descrptions

all_runs <- function(rawdata){
    # TODO: better summary meterics. maybe use habit number
    smry <- task_summary_data %>%
       select(id, ver, end=endtime, n_trials=n, perm,
              rt_mean,rt_sd,score,n_miss, n_keys_mean,
              avatar,understand,fun,feedback) %>%
       mutate(end=format(ymd_hms(end),"%H:%M"))
    run_info <- rawdata %>%
        mutate(vdate=format(vdate,"%y-%m-%d")) %>%
        select(id, age=survey_age, vdate, ver, task, blockseq) %>%
        distinct()

    left_join(run_info, smry,by=c("id","ver"))

}

smry_perms <- function(data, usetask=FALSE){
 grp <- vars(blockseq)
 if(usetask) grp <- vars(perm,blockseq, task)
 all_runs(data) %>%
    group_by(!!!grp) %>%
    summarise(n_trials=first(n_trials), n=n(),
            rt=mean(rt_mean), start=min(vdate), end=max(vdate)) %>%
    arrange(-as.numeric(gsub('-','',end)))
}

smry_pChoice<-function(data){
  data %>%
     group_by(id, blocktype) %>%
     summarize(choseFar = sum(choseFar, na.rm=T),
                avoidedFar = sum(avoidedFar, na.rm=T),
                pChoseFar = choseFar / (choseFar + avoidedFar)) %>%
    # hard coding block names requires maintenance
    #mutate(blocktype = fct_relevel(blocktype, c('init','switch1','rev2','devalue'))) %>%
    group_by(blocktype) %>%
    summarize(pChoseFar_m = mean(pChoseFar, na.rm=T),
              pChoseFar_sd = sd(pChoseFar, na.rm=T),
              pChoseFar_se = sd(pChoseFar, na.rm=T)/sqrt(n()),
              n=n())
} 



#### PLOTTING
data_far_only <- function(data)  far_only <- data %>% filter(!is.na(choseFar))  %>% arrange(trial)
data_no_far <- function(data)      no_far <- data %>% filter(is.na(choseFar)) %>% arrange(trial)

geom_block_rect <- function(d, gby, ylim=c(0,4)) {
    # gby should be at least var('blocktype')
    blocks <- d %>%
        group_by_at(gby) %>%
        summarise(xmin=min(trial), xmax=max(trial),
                  ymin=ylim[1], ymax=ylim[2])
    geom_rect(data=blocks, aes(x=NULL, color=NULL, shape=NULL, size=NULL, y=NULL,
                               ymax=ymax,ymin=ymin,xmax=xmax, xmin=xmin, fill=blocktype), alpha=.2)
}


# optimal choices during learning phase
plot_learn_optimal<-function(data){
   no_deval <- data %>% filter(!is.na(optimal_choice) & !grepl('devalue', blocktype))
   ggplot(no_deval) +
       aes(x=trial, y=1*optimal_choice, group=id, color=id) + 
       geom_block_rect(no_deval, vars('id','blocktype')) +
       geom_point() + 
       geom_ma(n = 10, ma_fun = EMA, color = "red", linetype=1) + 
       coord_cartesian(xlim = c(1,MAXTRIALS), ylim=c(0,1)) +
       facet_wrap(facets = vars(id)) +
       theme(legend.position = 'none')
}

plot_pref_far<-function(data) {
   # preference for far well by block
   far_only <- data_far_only(data)
   ggplot(far_only)+
     aes(x=trial, y=1*choseFar, group=id, color=id) + 
     geom_block_rect(far_only, vars('id','blocktype')) +
     geom_point() + 
     geom_ma(n = 10, ma_fun = EMA, color = "red", linetype=1) + 
     facet_wrap(facets = vars(id), ncol = 4) +
     coord_cartesian(xlim = c(1,MAXTRIALS), ylim=c(0,1)) +
     theme(legend.position = 'none')
}

# reversal learning (trials excluded far well as a choice)
plot_revlearn <- function(data) {
  no_far <- data_no_far(data)
  ggplot(no_far)+
    aes(x=trial, y=1*choseInitHigh, group=id, color=id) + 
    geom_block_rect(no_far, vars('id','blocktype')) +
    geom_point() + 
    geom_ma(n = 5, ma_fun = EMA, color = "red", linetype=1) + 
    facet_wrap(facets = vars(id), ncol = 4) +
    coord_cartesian(xlim = c(1,MAXTRIALS), ylim=c(0,1)) +
    theme(legend.position = 'none')
}


# group average learning
plot_grp_learn <- function(data, grp_ma_win=50, idv_ma_win=0){
   no_far <- data_no_far(data)
   p <- ggplot(no_far) +
     aes(x=trial, y=1*choseInitHigh) + 
     geom_block_rect(no_far, vars('blocktype','blockseq')) +
     geom_abline(slope=0, intercept=0.5, linetype=1) +
     geom_ma(n = 50, ma_fun = EMA, color = "red", linetype=1) + 
     coord_cartesian(xlim = c(1,MAXTRIALS), ylim = c(0,1)) +
     theme(legend.position = 'none') +
     facet_wrap(~blockseq)

   if(idv_ma_win>0) p <- p +
     #stat_smooth(aes(group=id), se=F, span=1.5, color='gray', method='loess')
     geom_ma(n = idv_ma_win, ma_fun = EMA, linetype=1, aes(group=id), color='gray',
             data= no_far %>% group_by(id) %>% filter(n()>3*idv_ma_win))
   return(p)
} 

# group average - far well, + indiv traces
plot_grp_far_trace<-function(data, idv_ma_win=20, grp_ma_win=150){
   # use idv_ma_win=0 to disable showing traces
  far_only <- data_far_only(data)
  p <- ggplot(far_only) +
     aes(x=trial, y=1*choseFar) + 
     geom_block_rect(far_only, vars('blocktype','blockseq')) +
     geom_abline(slope=0, intercept=0.5, linetype=1) +
     geom_ma(n = grp_ma_win, ma_fun = ZLEMA, linetype=1, color='blue')
     #stat_smooth(span=0.1, se=T) +
  if(idv_ma_win>0)
     # 2022-04-18 need to remove AEZL6P69UF6KE who hardly responded
     # so make sure we have enough samples in terms of idv_ma_win
     p <- p +
        geom_ma(data=far_only %>% group_by(id) %>% filter(n()>=3*idv_ma_win),
                n = idv_ma_win, ma_fun = ZLEMA, linetype=1, aes(group=id), color='gray')
     #stat_smooth(aes(group=id), se=F, span=1.5, color='gray', method='loess')

  p + coord_cartesian(xlim = c(1,MAXTRIALS), ylim = c(0,1)) +
     facet_wrap(~blockseq) +
     theme(legend.position = 'none')
}

plot_grp_nofar_trace_mvavg <- function(data){
   no_far_no_deval <- data %>% filter(is.na(choseFar) & !grepl('devalue',blocktype)) %>% arrange(trial)
   ggplot(no_far_no_deval) +
     aes(x=trial, y=1*optimal_choice) + 
     geom_block_rect(no_far_no_deval, vars('blocktype','blockseq')) +
     geom_abline(slope=0, intercept=0.5, linetype=1) +
     geom_ma(n = 25, ma_fun = EMA, color = "red", linetype=1) + 
     coord_cartesian(xlim = c(1,MAXTRIALS), ylim = c(0,1)) +
     facet_wrap(~blockseq) +
     theme(legend.position = 'none')
}


plot_grp_rt_trace_mvavg <- function(data){
   # group average - RT
   rt_data <- data %>% filter(!is.na(rt)) %>% arrange(trial)
   ggplot(rt_data) + aes(x=trial, y=rt, color=as.factor(choiceType)) + 
     geom_block_rect(rt_data, vars('blocktype','blockseq'), ylim=c(400,800)) +
     geom_abline(slope=0, intercept=0.5, linetype=1) +
     stat_smooth(span = 0.5) +
     coord_cartesian(xlim = c(1,MAXTRIALS), ylim = c(400,800)) +
     facet_wrap(~blockseq) +
     theme(legend.position = 'top')
}

pHabit_deval100 <- function(data) {
   # how often the "good" well is preferend
   # in the devalue_all_100 block
   habitBeh <- data %>% merge(task_summary_data %>% select(id,ver,timepoint,perm),
                              by=c("id","ver","timepoint")) %>%
       filter(grepl("devalue_all_100",blocktype)) %>%
       group_by(id, age.x, blockseq, task, perm) %>% 
       summarize(pHabit = sum(choseFar, na.rm=T) /
                         (sum(choseFar, na.rm=T) + sum(avoidedFar, na.rm=T)))
  }

plot_habit_line <- function(data){
   d  <- pHabit_deval100(data) %>% filter(age.x>18)
   ggplot(d)+
     aes(x=age.x, y=pHabit) +
     geom_smooth(method='loess') +
     geom_point(aes(color=blockseq, shape=grepl("mountain",perm)), size=3) +
     coord_cartesian(ylim=c(0,1)) +
     facet_wrap(~blockseq) +
     theme(legend.position = 'bottom') +
     ggtitle("habit in deval100 only")
}

plot_habit_hist  <- function(data){
   ggplot(pHabit_deval100(data))+
      aes(x=pHabit, fill=blockseq) +
      geom_histogram() +
      facet_grid(blockseq~.)
}


plot_idv_wf <- function(data){
  ## plot all trials. facet by id (currently, id is unique to each run)
  # color rectanges for block switches. hard coding first100 and first50 b/c '*unified' columns could have NA
  maxwell <- max(data$avoid_unified,na.rm=T)
  d_facet_id <- data %>% rename(age=age.x) %>%
      mutate(shortver=substr(gsub('.*(v[0-9]+).*','\\1',ver),0,10),
             shortid=substr(id,0,7),
             facet=paste(age,shortver,id))

  ggplot(d_facet_id) +
      aes(x=trial) +
      geom_block_rect(d_facet_id, vars('facet','blocktype')) +
      geom_point(aes(y=avoid_unified),color='gray') +
      geom_point(aes(y=picked_unified,color=optimal_choice,shape=score)) +
      facet_grid(facet~.) +
      scale_shape_manual(values=c(4,5,20)) +
      theme(strip.text.x = element_text(hjust = -0.02)) +
      labs(shape="scored?", colour="optimal?", y="side")
}
 
plot_age_hist<-function(data){
   # ggplot(habitBeh) + aes(age.x) + geom_histogram()
   data %>%
        group_by(id, age.x) %>%
        distinct %>%
        ggplot() + aes(age.x) %>%
        geom_histogram
}

# single plot
plot_idv_fname <- function(fname="data.tsv") plot_idv_wf(read_raw(fname))
