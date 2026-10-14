export function drawWorld(canvas, state, selected) {
 const c = canvas.getContext('2d'); c.imageSmoothingEnabled = false;
 const rect = (x,y,w,h,color) => { c.fillStyle=color; c.fillRect(x,y,w,h); };
 rect(0,0,960,576,'#95b974');
 for(let y=0;y<576;y+=24) for(let x=0;x<960;x+=24) { if((x*7+y*13)%11<3) rect(x+6,y+8,3,5,'#7fa763'); }
 rect(700,0,115,576,'#7aaeb3'); for(let y=0;y<576;y+=40) rect(715+(y%3)*10,y,55,3,'#a2ccd0');
 rect(0,185,700,65,'#d8c49a'); rect(215,245,60,331,'#d8c49a');
 // Cottage and roof
 rect(83,69,169,113,'#f1deb8'); rect(75,160,187,23,'#b59573');
 for(let i=0;i<5;i++) rect(67+i*13,36+i*12,199-i*26,13,'#b66d52');
 rect(145,122,40,60,'#725343'); rect(100,104,29,29,'#739b9b'); rect(201,104,29,29,'#739b9b'); rect(155,48,39,6,'#d98d6e');
 c.font='14px monospace'; c.fillStyle='#544c35'; c.fillText('HOME',145,213);
 // Trees, hedge and flowers
 for(const [x,y] of [[35,55],[325,70],[610,75],[870,45],[870,220],[880,470],[55,440],[635,450]]) { rect(x+15,y+34,12,37,'#795f43'); rect(x,y+12,43,37,'#4c7951'); rect(x+7,y,31,44,'#5f8f57'); rect(x+13,y+7,17,10,'#79a265'); }
 for(let x=300;x<660;x+=32) {rect(x,147,8,34,'#ede0b6'); rect(x,156,34,7,'#ede0b6');}
 for(let i=0;i<24;i++){ const x=317+(i%6)*51,y=275+Math.floor(i/6)*51,p=state.plots[i]; rect(x,y,46,46,p.tilled ? (p.watered?'#785d48':'#98714e'):'#adc486'); if(p.tilled) for(let k=0;k<3;k++)rect(x+5,y+10+k*11,35,2,'#7f5c42'); if(p.crop) { rect(x+22,y+21,4,15,'#517447'); rect(x+12,y+18,12,7,'#759951'); rect(x+26,y+12,11,9,'#5c8a44'); if(p.growth>=3){rect(x+15,y+28,19,12,'#f3d4bd');rect(x+21,y+38,7,5,'#e6b79f');} else if(p.growth>0) rect(x+15,y+26,17,6,'#88a95c'); if(p.watered) rect(x+36,y+5,4,6,'#91c7d7'); } if(i===selected){c.strokeStyle='#fff4ca';c.lineWidth=3;c.strokeRect(x-2,y-2,50,50);} }
 // Player
 rect(278,253,16,8,'#344940');rect(276,231,20,21,'#e1bd8e');rect(272,225,29,9,'#f0d38f');rect(279,216,16,11,'#f0d38f');rect(277,248,19,18,'#657e9e');rect(277,266,7,9,'#544e49');rect(290,266,7,9,'#544e49');
 // Produce crate and mushrooms
 rect(80,302,97,56,'#9d7651'); for(let x=90;x<170;x+=22)rect(x,307,5,44,'#bd9369');rect(77,314,103,8,'#cfa97d');
 c.fillStyle='#544c35';c.fillText('SHIPPING',83,385);
 for(const [x,y] of [[670,315],[97,490],[640,215],[35,330]]){rect(x+5,y+7,5,9,'#f0ddac');rect(x,y,16,8,'#d99b78');rect(x+3,y+1,3,3,'#fff0d1');}
}
export function plotAt(event, canvas) {const r=canvas.getBoundingClientRect(),x=(event.clientX-r.left)*960/r.width,y=(event.clientY-r.top)*576/r.height;const col=Math.floor((x-317)/51),row=Math.floor((y-275)/51);return col>=0&&col<6&&row>=0&&row<4 ? row*6+col : -1;}
