// parts of the task we can change with a flag
let tweaks = {'nocaptcha': 'skip audio confirmatin/captcha?',
              'photodiode': 'photodiode (sEEG)',
              'nofar': 'make all wells equadistant (no far well)?',
              'yesfar': 'far well ~3x as far as close (this used if conflict)',
              'mx95': 'best well prob=95',
              'VERBOSEDEBUG': 'verbose debugging',
              'NO_TIMEOUT': 'disable timeout',
              'fewtrials': 'reduce trial count: only 1 pair ea. per block'
}
// settings to append to anchor of url
function ifchecked(name){
 let box =  document.querySelector("input[name="+name+"]").checked;
 return(box?name:"")
}

function get_anchor(){
    let landscape =  document.querySelector("#landscape")
    let ltype = landscape.selectedOptions[landscape.selectedIndex].value;
    let tweakstr = Object.keys(tweaks)
                 .map(x=>ifchecked(x))
                 .filter(x=>x!="")
                 .join("&");
    return("#" + ltype + (tweakstr?("&"+tweakstr):""))
}

// put tweak checkboxs in link
function add_tweaks(){
   let f =  document.querySelector("#task_setting_tweaks");
   Object.keys(tweaks).forEach(x =>
         f.innerHTML += ('<input type="checkbox" name="'+ x +'"/> '+ tweaks[x] +'? <br>'))
} 
