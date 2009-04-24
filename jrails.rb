# jrails.rb by Jeff Larkin
# change a rails project from prototype to jquery

plugin 'jrails', :git => 'git://github.com/aaronchi/jrails.git'
inside('public/javascripts') do
  run "rm -f controls.js  dragdrop.js  effects.js  prototype.js"
end
rake 'jrails:update:javascripts'
