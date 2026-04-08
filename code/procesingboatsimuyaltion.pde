import processing.serial.*;

String SERIAL_PORT = "COM9";
int    BAUD_RATE   = 115200;

Serial myPort;

// ===== SET YOUR THRESHOLD HERE =====
float DANGER_THRESHOLD = 60;  // delay/alarm triggers ONLY at this angle
// ====================================

float rawRoll=0, rawPitch=0, roll=0, pitch=0;
float rawTilt=0, tilt=0;
float SMOOTH = 0.07;
float t = 0;

float lat=17.385044, lng=78.486671;
boolean gpsValid=false, isDanger=false;
float flashAlpha=0;

String[] logLines  = new String[6];
color[]  logColors = new color[6];
int      logCount  = 0;

boolean draggingThreshold = false;

color C_ACCENT  = color(0,212,255);
color C_ACCENT2 = color(0,255,157);
color C_DANGER  = color(255,59,92);
color C_WARN    = color(255,184,0);
color C_DIM     = color(58,106,138);
color C_PANEL   = color(7,24,40,210);
color C_BORDER  = color(13,51,82);
color C_TEXT    = color(200,232,255);

PFont monoFont;

void setup() {
  size(1200,750,P3D);
  frameRate(60);
  monoFont = createFont("Courier New",12,true);
  for(int i=0;i<6;i++){logLines[i]="";logColors[i]=C_DIM;}
  addLog("System initialized", C_ACCENT2);
  addLog("Threshold: "+(int)DANGER_THRESHOLD+" deg", C_WARN);
  try {
    myPort = new Serial(this, SERIAL_PORT, BAUD_RATE);
    myPort.bufferUntil('\n');
    addLog("Serial: "+SERIAL_PORT, C_ACCENT2);
  } catch(Exception e) {
    addLog("Serial FAILED - DEMO mode", C_WARN);
  }
}

void draw() {
  t = frameCount * 0.018;

  roll  += (rawRoll  - roll)  * SMOOTH;
  pitch += (rawPitch - pitch) * SMOOTH;
  tilt  += (rawTilt  - tilt)  * SMOOTH;

  // Demo mode — swings up to 70° so you can test the 60° threshold
  if (myPort == null) {
    rawRoll  = sin(t*0.7) * 70;
    rawPitch = cos(t*0.5) * 30;
    rawTilt  = max(abs(rawRoll), abs(rawPitch));
    gpsValid=true; lat=17.385044; lng=78.486671;
  }

  // isDanger ONLY triggers at your threshold — not at 30
  isDanger = tilt > DANGER_THRESHOLD;

  if (isDanger) flashAlpha = min(flashAlpha+5, 90);
  else          flashAlpha = max(flashAlpha-4, 0);

  background(5,12,28);
  drawSky();

  camera(width*0.62,height*0.28,520,
         width*0.48,height*0.52,0,
         0,1,0);

  ambientLight(28,50,105);
  directionalLight(255,218,135,-0.5,-1.0,-0.3);
  directionalLight(75,135,215,0.6,-0.3,0.5);
  directionalLight(195,115,45,0.0,-0.2,1.0);
  directionalLight(15,60,95,0.0,1.0,0.0);

  float waveH = waveAt(0,0,t)*26;
  drawOcean(waveH);

  pushMatrix();
    translate(width/2, height/2+80+waveH, 0);
    rotateX(radians(-pitch));
    rotateZ(radians(roll));
    scale(20);
    drawBoat();
  popMatrix();

  drawOceanFront(waveH);
  drawWaterEffects(waveH);

  camera(); perspective();
  hint(DISABLE_DEPTH_TEST);
  noLights();

  // Flash ONLY when tilt > DANGER_THRESHOLD (60)
  if (flashAlpha > 0) {
    noStroke(); fill(255,59,92,flashAlpha);
    rect(0,0,width,height);
  }

  drawHeader();
  drawTiltGauge(18,  70,160,160, roll,  "ROLL",  C_ACCENT);
  drawTiltGauge(18, 250,160,160, pitch, "PITCH", C_ACCENT2);
  drawInfoPanel(width-210, 70, 195, 395);
  drawLogPanel(18, 430, 380, 160);
  drawHorizonBar(width/2-140, height-54, 280, 36);
  drawThresholdPanel(18, 620, 380, 95);

  hint(ENABLE_DEPTH_TEST);
}

// ═══════════════════════════════════════════════════════
//  HEADER
// ═══════════════════════════════════════════════════════
void drawHeader() {
  noStroke(); fill(5,14,32,210); rect(0,0,width,52);
  stroke(C_BORDER); strokeWeight(1); line(0,52,width,52);
  noStroke();
  for(int x=0;x<width;x++){fill(0,212,255,sin(map(x,0,width,0,PI))*160);rect(x,51,1,1);}

  textFont(monoFont);
  fill(C_ACCENT); textSize(15);
  text("⚓  BOAT TILT MONITOR", 22, 32);

  // Tilt + threshold in header — colour only changes at threshold
  float pct = tilt / DANGER_THRESHOLD;
  color hCol = isDanger ? C_DANGER : pct > 0.75 ? C_WARN : C_ACCENT2;
  fill(hCol); textSize(13);
  text("TILT: "+nf(tilt,1,1)+"°  /  LIMIT: "+(int)DANGER_THRESHOLD+"°",
       width/2-90, 32);

  String stxt = isDanger ? "● DANGER" : "● SAFE";
  color  scol = isDanger ? C_DANGER : C_ACCENT2;
  textSize(12);
  float sw = textWidth(stxt)+26;
  noStroke(); fill(isDanger?color(35,4,10,200):color(0,28,18,200));
  stroke(scol); strokeWeight(1); rect(width-sw-22,13,sw,26,2);
  noStroke(); fill(scol); text(stxt,width-sw-9,31);

  fill(myPort!=null?C_ACCENT2:C_WARN); ellipse(width-sw-55,26,8,8);
  fill(C_DIM); textSize(9);
  text(myPort!=null?"LIVE":"DEMO",width-sw-82,30);
}

// ═══════════════════════════════════════════════════════
//  TILT GAUGE — red zone starts at DANGER_THRESHOLD
// ═══════════════════════════════════════════════════════
void drawTiltGauge(float px,float py,float pw,float ph,
                   float val,String lbl,color col) {
  noStroke(); fill(C_PANEL); rect(px,py,pw,ph,4);
  stroke(C_BORDER); strokeWeight(1); noFill(); rect(px,py,pw,ph,4);

  float cx=px+pw/2, cy=py+ph/2+10, r=pw*0.36;
  float startA=radians(140), endA=radians(400);
  float neutral=map(0,-90,90,startA,endA);
  float mapped =map(val,-90,90,startA,endA);

  // Background arc
  noFill(); stroke(C_BORDER); strokeWeight(7);
  arc(cx,cy,r*2,r*2,startA,endA);

  // Value arc — green until threshold, red after
  color arcCol = (abs(val) > DANGER_THRESHOLD) ? C_DANGER : col;
  stroke(arcCol); strokeWeight(7);
  arc(cx,cy,r*2,r*2,min(neutral,mapped),max(neutral,mapped));

  // Regular tick marks every 30°
  stroke(C_DIM); strokeWeight(1);
  for(float v=-90;v<=90;v+=30){
    float a=map(v,-90,90,startA,endA);
    line(cx+cos(a)*(r-12),cy+sin(a)*(r-12),cx+cos(a)*(r+2),cy+sin(a)*(r+2));
  }

  // Threshold marker lines — at DANGER_THRESHOLD not 30
  stroke(C_DANGER); strokeWeight(2.5);
  for(int s:new int[]{-1,1}){
    float a=map(s*DANGER_THRESHOLD,-90,90,startA,endA);
    line(cx+cos(a)*(r-18),cy+sin(a)*(r-18),cx+cos(a)*(r+8),cy+sin(a)*(r+8));
    // Small label at threshold line
    fill(C_DANGER); textSize(7); textAlign(CENTER);
    text((int)DANGER_THRESHOLD+"°",
         cx+cos(a)*(r+18), cy+sin(a)*(r+18)+3);
  }

  // Needle
  stroke(arcCol); strokeWeight(2.5);
  line(cx,cy,cx+cos(mapped)*(r-16),cy+sin(mapped)*(r-16));
  noStroke(); fill(arcCol); ellipse(cx,cy,8,8);

  // Value text
  fill(arcCol); textFont(monoFont); textSize(16); textAlign(CENTER);
  text(nf(val,1,1)+"°",cx,cy+14);
  fill(C_DIM); textSize(9);
  text(lbl,cx,cy+28);
  textAlign(LEFT);
}

// ═══════════════════════════════════════════════════════
//  INFO PANEL — all colours tied to DANGER_THRESHOLD
// ═══════════════════════════════════════════════════════
void drawInfoPanel(float px,float py,float pw,float ph) {
  noStroke(); fill(C_PANEL); rect(px,py,pw,ph,4);
  stroke(C_BORDER); strokeWeight(1); noFill(); rect(px,py,pw,ph,4);
  noStroke();
  for(int x=0;x<(int)pw;x++){
    fill(0,212,255,sin(map(x,0,pw,0,PI))*120);rect(px+x,py,1,1);
  }
  textFont(monoFont); fill(C_DIM); textSize(9);
  text("◈ SENSOR DATA",px+12,py+18);

  float ry=py+36, rh=28;

  // Tilt row — colour ramps from green→yellow→red
  // but ONLY goes red at DANGER_THRESHOLD, not at 30
  float tiltPct = tilt / DANGER_THRESHOLD;
  color tiltCol = isDanger ? C_DANGER
                : tiltPct > 0.75 ? C_WARN
                : C_ACCENT2;
  infoRow(px+10,ry,      pw-20,"TILT", nf(tilt,1,1)+"°",  tilt/90.0, tiltCol);
  infoRow(px+10,ry+rh,   pw-20,"ROLL", nf(roll,1,1)+"°",  (roll+90)/180.0, C_ACCENT);
  infoRow(px+10,ry+rh*2, pw-20,"PITCH",nf(pitch,1,1)+"°", (pitch+90)/180.0,C_ACCENT2);

  stroke(C_BORDER); strokeWeight(1);
  line(px+10,ry+rh*3+4,px+pw-10,ry+rh*3+4);

  fill(C_DIM); textSize(9); noStroke();
  text("◈ GPS LOCATION",px+12,ry+rh*3+20);
  float gy=ry+rh*3+34;
  gpsRow2(px+10,gy,    pw-20,"LAT",   gpsValid?nf(lat,1,6)+"°":"--",  gpsValid);
  gpsRow2(px+10,gy+26, pw-20,"LNG",   gpsValid?nf(lng,1,6)+"°":"--",  gpsValid);
  gpsRow2(px+10,gy+52, pw-20,"STATUS",gpsValid?"LOCKED":"SEARCHING",   gpsValid);

  stroke(C_BORDER); line(px+10,gy+76,px+pw-10,gy+76);

  fill(C_DIM); textSize(9); noStroke();
  text("◈ THRESHOLD",px+12,gy+92);

  // Shows actual threshold — not hardcoded 30
  color thCol = DANGER_THRESHOLD >= 60 ? C_ACCENT2
              : DANGER_THRESHOLD >= 40 ? C_WARN : C_DANGER;
  fill(thCol); textSize(12);
  text("DANGER > "+(int)DANGER_THRESHOLD+(char)176, px+12, gy+112);
  fill(C_DIM); textSize(8);
  text("use slider or +/- keys", px+12, gy+126);

  // Gradient bar — colour split at DANGER_THRESHOLD not 30
  float bx=px+12, bw2=pw-24;
  noStroke(); fill(0,30,50); rect(bx,gy+132,bw2,8,2);
  float splitFrac = DANGER_THRESHOLD/90.0;
  for(int i=0;i<(int)bw2;i++){
    float frac=i/bw2;
    // Green zone: 0 → threshold
    // Red zone:   threshold → 90
    color c = frac < splitFrac
            ? lerpColor(C_ACCENT2, C_WARN, frac/splitFrac)
            : lerpColor(C_WARN, C_DANGER, (frac-splitFrac)/(1.0-splitFrac));
    fill(c); rect(bx+i,gy+132,1,8);
  }

  // Current tilt marker (white)
  float markerX=bx+constrain(tilt/90.0,0,1)*bw2;
  stroke(255); strokeWeight(2);
  line(markerX,gy+129,markerX,gy+143);

  // Threshold marker (red) — at actual threshold position
  float threshX=bx+(DANGER_THRESHOLD/90.0)*bw2;
  stroke(C_DANGER); strokeWeight(2);
  line(threshX,gy+128,threshX,gy+144);

  // Bar labels
  noStroke(); fill(C_DIM); textSize(8);
  text("0°",bx,gy+157);
  fill(C_DANGER); textAlign(CENTER);
  text((int)DANGER_THRESHOLD+"°",threshX,gy+157);
  fill(C_DIM); textAlign(RIGHT);
  text("90°",bx+bw2,gy+157);
  textAlign(LEFT);
}

void infoRow(float x,float y,float w,String lbl,String val,float frac,color col){
  stroke(C_BORDER);strokeWeight(1);line(x,y+24,x+w,y+24);
  fill(C_DIM);textSize(9);noStroke();text(lbl,x,y+12);
  noStroke();fill(0,25,45);rect(x,y+14,w,6,1);
  fill(col);rect(x,y+14,constrain(frac,0,1)*w,6,1);
  fill(col);textSize(11);textAlign(RIGHT);text(val,x+w,y+12);textAlign(LEFT);
}

void gpsRow2(float x,float y,float w,String lbl,String val,boolean ok){
  fill(C_DIM);textSize(9);noStroke();text(lbl,x,y+11);
  fill(ok?C_ACCENT:C_WARN);textSize(10);textAlign(RIGHT);
  text(val,x+w,y+11);textAlign(LEFT);
  stroke(C_BORDER);strokeWeight(1);line(x,y+14,x+w,y+14);
}

// ═══════════════════════════════════════════════════════
//  THRESHOLD PANEL
// ═══════════════════════════════════════════════════════
void drawThresholdPanel(float px,float py,float pw,float ph){
  noStroke();fill(C_PANEL);rect(px,py,pw,ph,4);
  stroke(C_BORDER);strokeWeight(1);noFill();rect(px,py,pw,ph,4);

  textFont(monoFont);fill(C_WARN);textSize(9);
  text("◈ DANGER THRESHOLD  (drag slider)",px+12,py+18);

  float splitFrac=DANGER_THRESHOLD/90.0;
  color thCol = DANGER_THRESHOLD>=60?C_ACCENT2:DANGER_THRESHOLD>=40?C_WARN:C_DANGER;

  fill(thCol);textSize(22);textAlign(RIGHT);
  text((int)DANGER_THRESHOLD+(char)176,px+pw-12,py+50);
  textAlign(LEFT);

  fill(C_DIM);textSize(9);
  text("SAFE  ← tilt limit →  EXTREME",px+12,py+62);

  float sx=px+12,sy=py+72,sw=pw-24;
  noStroke();fill(0,25,45);rect(sx,sy,sw,10,3);

  // Gradient — split at threshold
  for(int i=0;i<(int)sw;i++){
    float frac=i/sw;
    color c=frac<splitFrac
           ?lerpColor(C_ACCENT2,C_WARN,frac/splitFrac)
           :lerpColor(C_WARN,C_DANGER,(frac-splitFrac)/(1.0-splitFrac));
    fill(c);rect(sx+i,sy,1,10);
  }

  float handleX=sx+(DANGER_THRESHOLD/90.0)*sw;
  stroke(255);strokeWeight(2);
  line(handleX,sy-4,handleX,sy+14);
  noStroke();fill(255);ellipse(handleX,sy+5,12,12);
  fill(thCol);textSize(8);textAlign(CENTER);
  text((int)DANGER_THRESHOLD+"°",handleX,sy-7);
  textAlign(LEFT);

  // Preset buttons — 25 35 45 60 75
  int[] presets={25,35,45,60,75};
  float bx=px+12,bby=py+ph-22,bw3=54,bh=18;
  for(int i=0;i<presets.length;i++){
    boolean active=abs(DANGER_THRESHOLD-presets[i])<1;
    noStroke();
    fill(active?thCol:color(0,30,55));
    rect(bx+i*(bw3+6),bby,bw3,bh,3);
    fill(active?color(5,12,28):C_DIM);
    textSize(9);textAlign(CENTER);
    text(presets[i]+"°",bx+i*(bw3+6)+bw3/2,bby+13);
    textAlign(LEFT);
  }
}

// ═══════════════════════════════════════════════════════
void mousePressed(){
  float px=18,py=620,pw=380;
  float sx=px+12,sy=py+72,sw=pw-24;
  if(mouseX>=sx&&mouseX<=sx+sw&&mouseY>=sy-8&&mouseY<=sy+18){
    draggingThreshold=true;
    updateThresholdFromMouse();
  }
  int[] presets={25,35,45,60,75};
  float bx=px+12,bby=py+95-22,bw3=54,bh=18;
  for(int i=0;i<presets.length;i++){
    float bl=bx+i*(bw3+6);
    if(mouseX>=bl&&mouseX<=bl+bw3&&mouseY>=bby&&mouseY<=bby+bh){
      DANGER_THRESHOLD=presets[i];
      addLog("Threshold → "+(int)DANGER_THRESHOLD+"°",C_WARN);
    }
  }
}

void mouseDragged(){if(draggingThreshold)updateThresholdFromMouse();}

void mouseReleased(){
  if(draggingThreshold)addLog("Threshold → "+(int)DANGER_THRESHOLD+"°",C_WARN);
  draggingThreshold=false;
}

void updateThresholdFromMouse(){
  float px=18,pw=380,sx=px+12,sw=pw-24;
  float frac=constrain((mouseX-sx)/sw,0,1);
  DANGER_THRESHOLD=constrain(round(frac*90),5,85);
}

void keyPressed(){
  if(key=='+'||key=='='){DANGER_THRESHOLD=constrain(DANGER_THRESHOLD+5,5,85);addLog("Threshold → "+(int)DANGER_THRESHOLD+"°",C_WARN);}
  if(key=='-')          {DANGER_THRESHOLD=constrain(DANGER_THRESHOLD-5,5,85);addLog("Threshold → "+(int)DANGER_THRESHOLD+"°",C_WARN);}
}

// ═══════════════════════════════════════════════════════
void drawLogPanel(float px,float py,float pw,float ph){
  noStroke();fill(C_PANEL);rect(px,py,pw,ph,4);
  stroke(C_BORDER);strokeWeight(1);noFill();rect(px,py,pw,ph,4);
  fill(C_DIM);textSize(9);noStroke();text("◈ EVENT LOG",px+12,py+18);
  for(int i=0;i<min(logCount,5);i++){fill(logColors[i]);textSize(10);text(logLines[i],px+12,py+36+i*24);}
  if(isDanger){
    noStroke();fill(red(C_DANGER),green(C_DANGER),blue(C_DANGER),180+sin(frameCount*0.2)*60);
    rect(px+pw-80,py+8,72,20,2);
    fill(255);textSize(9);textAlign(CENTER);text("⚠ DANGER",px+pw-44,py+21);textAlign(LEFT);
  }
}

void drawHorizonBar(float px,float py,float pw,float ph){
  noStroke();fill(C_PANEL);rect(px,py,pw,ph,3);
  stroke(C_BORDER);strokeWeight(1);noFill();rect(px,py,pw,ph,3);
  float cx=px+pw/2,cy=py+ph/2;
  pushMatrix();translate(cx,cy);rotate(radians(-roll));
  stroke(isDanger?C_DANGER:C_ACCENT);strokeWeight(1.5);
  line(-pw*0.4,pitch*0.15,pw*0.4,pitch*0.15);
  noStroke();fill(10,40,80,80);rect(-pw*0.4,-ph,pw*0.8,ph+pitch*0.15);
  fill(20,55,15,80);rect(-pw*0.4,pitch*0.15,pw*0.8,ph);
  popMatrix();
  stroke(C_ACCENT2);strokeWeight(1.5);
  line(cx-20,cy,cx-6,cy);line(cx+6,cy,cx+20,cy);line(cx,cy-8,cx,cy+8);
  noStroke();fill(C_ACCENT2);ellipse(cx,cy,4,4);
  fill(C_DIM);textSize(8);textAlign(CENTER);text("HORIZON",cx,py+ph-4);textAlign(LEFT);
}

void addLog(String msg,color col){
  for(int i=5;i>0;i--){logLines[i]=logLines[i-1];logColors[i]=logColors[i-1];}
  String ts=nf(hour(),2)+":"+nf(minute(),2)+":"+nf(second(),2);
  logLines[0]=ts+"  "+msg;logColors[0]=col;logCount=min(logCount+1,6);
}

// ═══════════════════════════════════════════════════════
void serialEvent(Serial p){
  String data=p.readStringUntil('\n');
  if(data==null)return;
  data=trim(data);
  String[] v=split(data,',');
  if(v.length>=2){rawRoll=float(v[0]);rawPitch=float(v[1]);}
  if(v.length>=3)rawTilt=float(v[2]);
  else rawTilt=max(abs(rawRoll),abs(rawPitch));
  if(v.length>=6){lat=float(v[3]);lng=float(v[4]);gpsValid=v[5].trim().equals("1");}

  // Danger ONLY at DANGER_THRESHOLD — not at 30
  boolean nowDanger=rawTilt>DANGER_THRESHOLD;
  if(nowDanger&&!isDanger)addLog("DANGER! Tilt="+nf(rawTilt,1,1)+"°",C_DANGER);
  if(!nowDanger&&isDanger)addLog("Back to SAFE",C_ACCENT2);
}

// ═══════════════════════════════════════════════════════
float waveAt(float x,float z,float time){
  return sin(x*0.28+time)*0.70+cos(z*0.20+time*1.12)*0.50
        +sin((x+z)*0.14+time*0.76)*0.32+sin(x*0.48-z*0.26+time*1.32)*0.15;
}

void drawSky(){
  hint(DISABLE_DEPTH_TEST);noLights();noStroke();camera();
  for(int y=0;y<height;y++){float n=map(y,0,height,0,1);fill(lerpColor(color(8,20,52),color(14,38,78),n));rect(0,y,width,1);}
  randomSeed(99);
  for(int i=0;i<200;i++){float bri=random(130,255);fill(bri,bri,bri+10,random(140,230));ellipse(random(width),random(height*0.55),random(0.8,2.5),random(0.8,2.5));}
  fill(255,252,215,28);ellipse(width-110,58,72,72);
  fill(255,252,215,225);ellipse(width-110,58,46,46);
  fill(225,222,185,215);ellipse(width-103,54,42,42);
  for(int i=0;i<10;i++){fill(255,248,195,22-i*2);ellipse(width-110,height*0.62+i*22,20+i*14,5+i);}
  hint(ENABLE_DEPTH_TEST);
}

void drawOcean(float waveH){
  int segs=55;float sz=1300,step=sz/segs;noStroke();
  pushMatrix();translate(width/2,height/2+80,0);
  for(int ix=0;ix<segs;ix++)for(int iz=0;iz<segs;iz++){
    float x0=-sz/2+ix*step,z0=-sz/2+iz*step,x1=x0+step,z1=z0+step;
    float y00=waveAt(x0/66,z0/66,t)*26,y10=waveAt(x1/66,z0/66,t)*26;
    float y11=waveAt(x1/66,z1/66,t)*26,y01=waveAt(x0/66,z1/66,t)*26;
    float c=map(y00,-26,26,0,1);
    if(y00>19)fill(lerpColor(color(14,100,155),color(200,228,242),(y00-19)/7.0));
    else fill(lerpColor(color(3,35,85),color(14,100,155),c));
    beginShape(QUADS);vertex(x0,y00,z0);vertex(x1,y10,z0);vertex(x1,y11,z1);vertex(x0,y01,z1);endShape();
  }
  popMatrix();
}

void drawOceanFront(float waveH){
  int segs=55;float sz=1300,step=sz/segs;noStroke();
  pushMatrix();translate(width/2,height/2+80,0);
  for(int ix=0;ix<segs;ix++)for(int iz=0;iz<segs;iz++){
    float x0=-sz/2+ix*step,z0=-sz/2+iz*step,x1=x0+step,z1=z0+step;
    if(z0>-30)continue;
    float y00=waveAt(x0/66,z0/66,t)*26,y10=waveAt(x1/66,z0/66,t)*26;
    float y11=waveAt(x1/66,z1/66,t)*26,y01=waveAt(x0/66,z1/66,t)*26;
    float c=map(y00,-26,26,0,1);
    if(y00>19)fill(lerpColor(color(14,100,155),color(200,228,242),(y00-19)/7.0));
    else fill(lerpColor(color(3,35,85),color(14,100,155),c));
    beginShape(QUADS);vertex(x0,y00,z0);vertex(x1,y10,z0);vertex(x1,y11,z1);vertex(x0,y01,z1);endShape();
  }
  popMatrix();
}

void drawWaterEffects(float waveH){
  hint(DISABLE_DEPTH_TEST);noLights();noStroke();camera();
  float cx=width*0.50,cy=height*0.52;
  for(int i=0;i<14;i++){fill(185,218,232,map(i,0,14,175,0));float sp=i*13,bk=i*9;triangle(cx+185,cy,cx+185-bk,cy-sp*0.45,cx+185-bk,cy+sp*0.45);}
  for(int i=0;i<12;i++){fill(155,198,222,map(i,0,12,135,0));ellipse(cx-155-i*20,cy+9,26-i*1.8,7);}
  for(int i=0;i<12;i++){fill(155,198,222,map(i,0,12,135,0));ellipse(cx-155-i*20,cy-9,26-i*1.8,7);}
  fill(255,255,200,11);rect(0,cy-2,width,5);
  hint(ENABLE_DEPTH_TEST);
}

void drawBoat(){
  fill(130,24,24);stroke(85,12,12);strokeWeight(0.022);
  pushMatrix();translate(0,1.05,0);box(12.2,1.75,4.35);popMatrix();
  noStroke();fill(130,24,24);
  beginShape(TRIANGLES);
    vertex(6.1,0.18,2.18);vertex(6.1,1.93,2.18);vertex(9.7,1.05,0);
    vertex(6.1,0.18,-2.18);vertex(9.7,1.05,0);vertex(6.1,1.93,-2.18);
    vertex(6.1,0.18,2.18);vertex(9.7,1.05,0);vertex(6.1,0.18,-2.18);
    vertex(6.1,1.93,2.18);vertex(6.1,1.93,-2.18);vertex(9.7,1.05,0);
  endShape();
  fill(85,12,12);noStroke();pushMatrix();translate(0,1.88,0);box(11.8,0.26,0.52);popMatrix();
  noStroke();fill(238,218,38);pushMatrix();translate(0,0.14,0);box(17.0,0.20,4.42);popMatrix();
  fill(20,92,188);stroke(8,52,112);strokeWeight(0.024);pushMatrix();translate(0,-0.70,0);box(12.2,1.62,4.35);popMatrix();
  noStroke();fill(20,92,188);
  beginShape(TRIANGLES);
    vertex(6.1,-1.38,2.18);vertex(6.1,0.18,2.18);vertex(9.7,-0.28,0);
    vertex(6.1,-1.38,-2.18);vertex(9.7,-0.28,0);vertex(6.1,0.18,-2.18);
    vertex(6.1,-1.38,2.18);vertex(9.7,-0.28,0);vertex(6.1,-1.38,-2.18);
    vertex(6.1,0.18,2.18);vertex(6.1,0.18,-2.18);vertex(9.7,-0.28,0);
  endShape();
  fill(20,92,188);stroke(8,52,112);strokeWeight(0.024);pushMatrix();translate(-7.6,-0.42,0);box(2.5,2.18,4.35);popMatrix();
  fill(172,126,60);stroke(88,60,22);strokeWeight(0.018);pushMatrix();translate(0,-1.52,0);box(14.6,0.18,4.25);popMatrix();
  noStroke();
  for(int i=-4;i<=4;i++){fill(142,94,36);pushMatrix();translate(0,-1.44,i*0.468);box(14.4,0.032,0.062);popMatrix();}
  fill(102,62,28);
  for(int s=-1;s<=1;s+=2){pushMatrix();translate(0,-1.42,s*2.08);box(14.8,0.155,0.165);popMatrix();}
  fill(234,220,180);stroke(142,122,82);strokeWeight(0.028);pushMatrix();translate(-1.0,-2.60,0);box(4.5,2.24,2.95);popMatrix();
  fill(205,190,148);pushMatrix();translate(1.24,-2.60,0);box(0.052,2.24,2.95);popMatrix();
  noStroke();fill(90,66,36);pushMatrix();translate(-1.0,-3.76,0);box(4.88,0.21,3.18);popMatrix();
  fill(62,42,18);pushMatrix();translate(-1.0,-3.65,0);box(5.18,0.115,3.42);popMatrix();
  float[][] ww={{0.08,-2.60,1.50},{-1.65,-2.60,1.50},{0.08,-2.60,-1.50},{-1.65,-2.60,-1.50}};
  for(float[] w:ww){
    fill(138,200,235);noStroke();pushMatrix();translate(w[0],w[1],w[2]);box(0.82,0.58,0.052);popMatrix();
    fill(215,238,252,135);pushMatrix();translate(w[0]-0.14,w[1]-0.11,w[2]+(w[2]>0?1:-1)*0.028);box(0.19,0.19,0.018);popMatrix();
    fill(68,46,18);noStroke();pushMatrix();translate(w[0],w[1],w[2]+(w[2]>0?1:-1)*0.054);box(0.92,0.68,0.038);popMatrix();
  }
  fill(138,200,235);noStroke();pushMatrix();translate(1.24,-2.60,0);box(0.052,0.72,2.18);popMatrix();
  fill(115,68,25);pushMatrix();translate(1.24,-1.76,0.85);box(0.055,1.18,0.72);popMatrix();
  fill(205,158,32);pushMatrix();translate(1.28,-1.76,0.54);sphere(0.072);popMatrix();
  fill(185,148,88);noStroke();pushMatrix();translate(3.1,-1.52,0);cylinder(0.098,7.4,10);popMatrix();
  fill(155,120,65);pushMatrix();translate(3.1,-4.95,0);cylinder(0.52,0.32,12);popMatrix();
  pushMatrix();translate(3.1,-6.45,0);rotateX(PI/2);cylinder(0.062,3.85,8);popMatrix();
  stroke(148,118,58);strokeWeight(0.045);
  line(3.1,-7.3,0,-7.2,-1.3,1.95);line(3.1,-7.3,0,-7.2,-1.3,-1.95);line(3.1,-7.3,0,8.0,-1.3,0.0);
  stroke(125,100,52);strokeWeight(0.030);
  line(3.1,-6.45,1.92,3.1,-7.3,0);line(3.1,-6.45,-1.92,3.1,-7.3,0);noStroke();
  fill(42,42,42);pushMatrix();translate(-1.6,-3.78,0.70);cylinder(0.175,1.65,10);popMatrix();
  fill(12,12,12);pushMatrix();translate(-1.6,-4.68,0.70);cylinder(0.222,0.19,10);popMatrix();
  float smk=sin(t*2.2)*0.28;
  fill(75,75,80,88);pushMatrix();translate(-1.6+smk,-5.15,0.70);sphere(0.33);popMatrix();
  fill(65,65,70,62);pushMatrix();translate(-1.3+smk,-5.68,0.70);sphere(0.26);popMatrix();
  fill(55,55,60,38);pushMatrix();translate(-1.0+smk,-6.12,0.70);sphere(0.20);popMatrix();
  stroke(185,145,78);strokeWeight(0.055);line(3.4,-1.52,1.72,7.1,-4.05,1.72);
  stroke(175,175,175);strokeWeight(0.026);line(7.1,-4.05,1.72,7.8,0.38,1.72);noStroke();
  fill(38,112,30);
  float[][] nets={{0,0,0,1.05f,0.60f,0.90f},{0.48f,-0.27f,0.37f,0.63f,0.48f,0.58f},{-0.38f,-0.17f,-0.46f,0.78f,0.54f,0.64f}};
  for(float[] n:nets){pushMatrix();translate(2.3+n[0],-1.78+n[1],0.48+n[2]);scale(n[3],n[4],n[5]);sphere(0.83);popMatrix();}
  fill(175,136,46);doTorus(4.45,-1.40,-0.72,0.46,0.120);doTorus(5.15,-1.40,0.72,0.44,0.120);
  fill(108,78,35);stroke(75,47,15);strokeWeight(0.028);
  pushMatrix();translate(4.45,-1.78,0.18);box(0.90,0.68,0.68);popMatrix();
  pushMatrix();translate(5.22,-1.78,-0.92);box(0.90,0.68,0.68);popMatrix();
  fill(75,47,15);noStroke();
  pushMatrix();translate(4.45,-2.12,0.18);box(0.92,0.062,0.70);popMatrix();
  pushMatrix();translate(5.22,-2.12,-0.92);box(0.92,0.062,0.70);popMatrix();
  fill(40,57,77);noStroke();
  pushMatrix();translate(-4.45,-1.46,1.50);cylinder(0.37,0.92,12);popMatrix();
  pushMatrix();translate(-5.12,-1.46,-1.50);cylinder(0.37,0.92,12);popMatrix();
  fill(13,13,13);
  doTorus(-0.75,-0.78,2.36,0.37,0.115);doTorus(1.35,-0.78,2.36,0.37,0.115);doTorus(-3.10,-0.78,-2.36,0.37,0.115);
  fill(252,55,38);pushMatrix();translate(-3.3,-1.40,2.12);rotateX(PI/2);doTorus(0,0,0,0.36,0.095);popMatrix();
  fill(252,252,252);
  pushMatrix();translate(-3.3,-1.40,2.15);box(0.055,0.72,0.055);popMatrix();
  pushMatrix();translate(-3.3,-1.40,2.15);rotateZ(PI/2);box(0.055,0.72,0.055);popMatrix();
  pushMatrix();translate(-8.5,1.38,0);rotateX(t*5.0);fill(175,140,52);
  for(int b=0;b<3;b++){pushMatrix();rotateX(TWO_PI*b/3.0);translate(0,0.62,0);scale(0.9,0.9,0.13);sphere(0.33);popMatrix();}
  fill(135,105,38);sphere(0.16);popMatrix();
  fill(15,72,150);noStroke();pushMatrix();translate(-8.2,1.55,0);box(0.28,1.35,0.075);popMatrix();
  fill(32,32,32);pushMatrix();translate(-7.2,-0.95,0);box(0.95,0.75,1.15);popMatrix();
  fill(52,52,65);stroke(32,32,52);strokeWeight(0.036);
  pushMatrix();translate(-6.8,-1.24,-1.35);rotateX(PI/2);doTorus(0,0,0,0.38,0.090);popMatrix();
  noStroke();pushMatrix();translate(-6.8,-1.78,-1.35);cylinder(0.062,1.00,7);popMatrix();
  drawPerson(-4.4,1.30,color(192,38,22),color(122,72,22),false);
  drawPerson(1.55,-1.10,color(22,55,152),color(35,52,85),false);
  drawPerson(3.65,0.12,color(32,92,22),color(18,18,6),true);
}

void drawPerson(float px,float pz,color shirt,color hat,boolean lean){
  pushMatrix();translate(px,-1.52,pz);if(lean)rotateX(-0.22);noStroke();
  fill(24,38,62);
  pushMatrix();translate(-0.155,0.368,0);cylinder(0.112,0.80,7);popMatrix();
  pushMatrix();translate(0.155,0.368,0);cylinder(0.112,0.80,7);popMatrix();
  fill(14,10,5);
  pushMatrix();translate(-0.155,0.775,0.052);box(0.155,0.095,0.232);popMatrix();
  pushMatrix();translate(0.155,0.775,0.052);box(0.155,0.095,0.232);popMatrix();
  fill(shirt);pushMatrix();translate(0,-0.108,0);box(0.485,0.725,0.328);popMatrix();
  pushMatrix();translate(-0.328,-0.088,0);rotateZ(-0.46);cylinder(0.088,0.658,7);popMatrix();
  pushMatrix();translate(0.328,-0.088,0);rotateZ(0.46);cylinder(0.088,0.658,7);popMatrix();
  fill(185,115,72);
  pushMatrix();translate(0,-0.522,0);cylinder(0.092,0.165,8);popMatrix();
  pushMatrix();translate(0,-0.715,0);sphere(0.242);popMatrix();
  fill(hat);
  pushMatrix();translate(0,-0.948,0);cylinder(0.348,0.062,12);popMatrix();
  pushMatrix();translate(0,-1.058,0);cylinder(0.212,0.212,10);popMatrix();
  popMatrix();
}

void cylinder(float r,float h,int sides){
  float half=h/2.0;
  beginShape(QUAD_STRIP);
  for(int i=0;i<=sides;i++){float a=TWO_PI*i/sides;normal(cos(a),0,sin(a));vertex(cos(a)*r,-half,sin(a)*r);vertex(cos(a)*r,half,sin(a)*r);}
  endShape();
  beginShape(TRIANGLE_FAN);normal(0,-1,0);vertex(0,-half,0);
  for(int i=0;i<=sides;i++){float a=TWO_PI*i/sides;vertex(cos(a)*r,-half,sin(a)*r);}endShape();
  beginShape(TRIANGLE_FAN);normal(0,1,0);vertex(0,half,0);
  for(int i=sides;i>=0;i--){float a=TWO_PI*i/sides;vertex(cos(a)*r,half,sin(a)*r);}endShape();
}

void doTorus(float px,float py,float pz,float R,float r){
  pushMatrix();translate(px,py,pz);int seg=14,tube=8;
  for(int i=0;i<seg;i++){
    float a0=TWO_PI*i/seg,a1=TWO_PI*(i+1)/seg;
    float cx0=cos(a0)*R,cy0=sin(a0)*R,cx1=cos(a1)*R,cy1=sin(a1)*R;
    beginShape(QUAD_STRIP);
    for(int j=0;j<=tube;j++){float b=TWO_PI*j/tube,rb=cos(b)*r,rz=sin(b)*r;
      normal(cos(a0)*cos(b),sin(a0)*cos(b),sin(b));vertex(cx0+cos(a0)*rb,cy0+sin(a0)*rb,rz);
      normal(cos(a1)*cos(b),sin(a1)*cos(b),sin(b));vertex(cx1+cos(a1)*rb,cy1+sin(a1)*rb,rz);}
    endShape();
  }
  popMatrix();
}
