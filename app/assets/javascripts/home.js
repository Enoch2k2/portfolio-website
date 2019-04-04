
function tab(e) {
  e.preventDefault();
  e.stopPropagation();
  
  let sections = document.querySelectorAll('section');
  let tabs = document.querySelectorAll('.tabs li a');
  let active = document.querySelector(`.${this.id}`);
  for (let i = 0; i < sections.length; i++) {
    const section = sections[i];
    section.style.display = 'none';
  }
  active.style.display = 'block';
  for (let i = 0; i < tabs.length; i++) {
    const tab = tabs[i];
    tab.className = '';
  }
  this.className = 'active-tab';
}

window.addEventListener('load', function(){
  let tabs = document.querySelectorAll('.tabs li a');
  for (let i = 0; i < tabs.length; i++) {
    const tabE = tabs[i];
    tabE.addEventListener('click', tab);
  }
})
