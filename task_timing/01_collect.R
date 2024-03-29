#!/usr/bin/env Rscript

# 20220510WF - init
#  collect all std dev norm tests. lowest is best
suppressPackageStartupMessages(library(dplyr))
source('funcs.R')
max_catch <- function(f) read_timing(f) %>% timing_mat() %>% filter(prop=='catch',value==TRUE) %$% nrep %>% max

# read events. get max-in-a-row
read_all <- function(gen_ver="v1", total_dur=240, redo=FALSE) {
   outfile <- paste0(total_dur,'_',gen_ver,'_std_dev_tests.tsv')
   if(file.exists(outfile) && !redo){
      print(glue::glue("# reading {outfile}"))
      d <- read.table(outfile, header=T)
      return(d %>% mutate(maxcatch=ifelse('maxcatch'%in%names(.), maxcatch, 0)))
   }

   print(glue::glue("# making {outfile}"))
   events <- Sys.glob(paste0('out/',total_dur,'s/',gen_ver,'_*/events.txt'))
   print(glue::glue("# from {length(events)} events.txt files"))

   catches <- sapply(events, max_catch) # takes a few minutes
   catches_df <- data.frame(name=cname(events,tt=total_dur, v=gen_ver), maxcatch=catches)

   # read GLM
   run_std <- Sys.glob(paste0('out/',total_dur,'s/',gen_ver,'_*/stddevtests.tsv')) %>% lapply(read.table,header=T) %>% bind_rows
   #d <- left_join(catches_df, run_std)
   d <- run_std %>% mutate(maxcatch=-Inf)
   write.table(d, outfile, row.names=F)
   return(d)
}

simplify_lc <- function(d, max_rep_catch=2) {
 d %>%
    filter(maxcatch < max_rep_catch) %>% # first instance is nrep == 0
    #arrange(choice_LC) %>%
    select(name,choice_LC,choice.fbk_LC, good.nogood_LC, g_fbk.ng_fbk_LC) %>%
    rowwise() %>% mutate(sum_LC = sum(c_across(-name))) %>% ungroup() %>%
    arrange(sum_LC)
}

rank_LC <- function(d) {
 d %>%
    simplify_lc() %>%
    select(-sum_LC) %>%
    mutate(across(matches("_LC"), rank)) %>%
    #mutate(across(matches("_LC"), function(x) scale(x-min(x), center=F))) %>%
    # new sum for rank. prev sum was LC
    rowwise() %>% mutate(overall = sum(c_across(-name)))
}

## inspect differences of min(iti) and total_duration
head_miniti<-function(v, miniti, dur="240", n=Inf)
   read.table(paste0(dur,'_',v,'_std_dev_tests.tsv'), header=T) %>%
      simplify_lc() %>% head(n=n) %>%
      mutate(miniti=miniti, totaldur=dur)


### pick
#d_lc <- read_all(gen_ver="v1.5", total_dur=280)
#d_lc <- read_all(gen_ver="v1-nocatch", total_dur=185)
#d_lc <- read_all(gen_ver="v1.5-nocatch", total_dur=185)
#d_lc <- read_all(gen_ver="v1.5-nocatch", total_dur=134)
#d_lc <- read_all(gen_ver="v1.5-nocatch-qwalk", total_dur=185)
# 20220015
#d_lc <- read_all(gen_ver="v1.5-nocatch-qwalk_45", total_dur=185)
# 20221024
d_lc <- read_all(gen_ver="v1.5-nocatch-qwalk_50", total_dur=200.34)
d_rank <- d_lc %>%  rank_LC()
# show
#d_rank %>% arrange(choice.fbk_LC)  %>%  head %>% print
d_rank %>% arrange(overall) %>% head %>% print.data.frame(row.names=F)

# library(ggplot2)
# theme_set(cowplot::theme_cowplot())
# ggplot(d) + aes(x=choice_LC, y=choice.fbk_LC) + geom_point() + geom_smooth()

iti_varations <-
   rbind(
      #head_miniti("v025",.25),
      #head_miniti("v1","1.0"),
      #head_miniti("v1.5",1.5),
      #head_miniti("v1", 1.0, 280),
      #head_miniti("v1.5", 1.5, 280),
      #head_miniti("v1-nocatch",1.0,185),
      #head_miniti("v1.5-nocatch",1.5,185),
      #head_miniti("v1.5-nocatch",1.5,134),
      #head_miniti("v1.5-nocatch-qwalk","1.50",185),
      head_miniti("v1.5-nocatch-qwalk_45","1.500",185),
      head_miniti("v1.5-nocatch-qwalk_50","1.500",200.34)#,
      #read.table('../results/1d/wftest/std_dev_tests.tsv',h=T) %>% mutate(maxcatch=0) %>%
      #   simplify_lc %>%
      #   mutate(name='v2-410-102-wf',miniti=1.5, totaldur=410)
      ) %>%
  mutate(miniti=as.factor(miniti))

library(ggplot2)
library(cowplot)
theme_set(theme_cowplot())
iti_var_g_ng<-ggplot(iti_varations) +
   aes(x=choice_LC, y=good.nogood_LC, size=sum_LC, color=miniti) +
   geom_point(alpha=.5) +
   ggtitle("min(iti) LCs")+
   facet_wrap(~totaldur)

# NB. no catch trials. dont care too much about choice-fbk now
#     hard to separate without a variable time delay
iti_var_g_choicefbk<-ggplot(iti_varations) +
   aes(x=choice_LC, y=choice.fbk_LC, size=sum_LC, color=miniti) +
   geom_point(alpha=.5) +
   #ggtitle("min(iti) LCs")+
   facet_wrap(~totaldur)

iti_var_plt <- plot_grid(iti_var_g_ng + theme(legend.position ='none'),
                         iti_var_g_choicefbk,
                         align="h")
ggsave(iti_var_plt, file='imgs/iti_variations.pdf', width=8, height=5)

#rbind(head_miniti("v1",1.0, 280),
#      head_miniti("v1.5",1.5, 280)) %>%
#  mutate(miniti=as.factor(miniti)) %>%
#  ggplot() + aes(x=choice_LC, y=choice.fbk_LC, size=sum_LC, color=miniti) + geom_point(alpha=.5) +
#  ggtitle("min(iti) LCs (280s)")
