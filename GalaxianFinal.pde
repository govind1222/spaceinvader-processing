/*
*/
import sprites.utils.*;
import sprites.maths.*;
import sprites.*;

// The dimensions of the monster grid.
int monsterCols = 10; // 10
int monsterRows = 5; // 5 default
//missile speeds
int missileSpeed = 500;
int fireballSpeed2 = 700, fireballSpeed1 = 550, fireballTimer = 50;

int rndl = -20, rndh = 70; 
int idxf; // to keep track of the firemonster
int mmStep = 1; 
int highscore = 0;

//keeping track of game score
int score = 0; 
int fallingMonsterPts = 20, gridMonsterPts = 10, missedShot = 5, fallingGotAway = 50, clearedScreen = 100, dfireball = 3;

int yOffset = 1;
int difficulty = 100; // Lower difficulty values introduce a more random falling monster descent.

//controls how long the powerups last
int timerDuration = 10000; //10 seconds
int freezeTimer = 0;
int shieldTimer = 0;
int helperShipTimer = 0;
int speedUpTimer = 0;

boolean gameMode = true; // realistically woule be an int or something that can hold more values but there are only two so save space
boolean shots = true;
boolean enemyShipsFreezed = false, shipInvincible = false, helperShipActive = false, speedUpActive = false;
boolean gameOver = false;
boolean hard = false;

double upRadians = 4.71238898, downRadians = -4.71238898;
double fmRightAngle = 0.3490, fmLeftAngle = 2.79253; // 20 and 160 degrees respectively
double fmSpeed = 150;

long mmCounter = 0;

Sprite ship, missile, fallingMonster, explosion, gameOverSprite, fireball, fireMonster; // the current spite is a placeholder
Sprite freezeShips, shieldIcon, shieldBubble, helpPowerUp, helperShip, helperMissile, speedUp;
Sprite monsters[] = new Sprite[monsterCols * monsterRows];

int []xStars = new int[5000];
int []yStars = new int[5000];

KeyboardController kbController;
SoundPlayer soundPlayer;
StopWatch stopWatch = new StopWatch();

//runs once before draw and pre functions execute
//set up and intialize data for the game
void setup() {
  kbController = new KeyboardController(this);
  soundPlayer = new SoundPlayer(this);  
  // Ship Explosion Sprite
  explosion = new Sprite(this, "explosion_strip16.png", 17, 1, 90);
  explosion.setScale(1);
  // Game Over Sprite
  gameOverSprite = new Sprite(this, "gameOver.png", 100);
  gameOverSprite.setDead(true);
  // register the function (pre) that will be called
  // by Processing before the draw() function. 
  registerMethod("pre", this);
  size(700, 500);
  S4P.messagesEnabled(true);
  buildSprites();
  resetMonsters();
  initializeStars();
}

// Executed before draw() is called 
public void pre() {    
  checkKeys(); 
  processCollisions(); 
  moveMonsters(); 
  randomizePowerUpMovement();
  // If missile flies off screen
  if (!missile.isDead() && !missile.isOnScreem()) {
    score -= missedShot;   
    stopMissile(missile);
  }

  if (helperShipActive && helperMissile != null) {
    if (!helperMissile.isDead() && !helperMissile.isOnScreem()) {
      stopMissile(helperMissile);
    }
  }

  if (!fireball.isDead() && !fireball.isOnScreem()) {
    score += dfireball; 
    stopFireball();
  }
  if (pickNonDeadMonster() == null) {
    if (!gameOver) {
      shots = false;
      fireball.setDead(true);
      score += clearedScreen;
    }
    resetMonsters();
  }
  // if falling monster is off screen
  if (fallingMonster == null || !fallingMonster.isOnScreem()) { 
    replaceFallingMonster();
  }
  S4P.updateSprites(stopWatch.getElapsedTime());
} 

//called for every frame
public void draw() {

  if (score > highscore) {
    highscore = score;
  }

  background(0); 
  // change the color based on gamemode 
  if (!gameOver && gameMode) {
    stroke(255);
  } else if (!gameMode) {
    stroke(0, 255, 255);
  }
  drawStars();
  drawScore(); 
  //gamemove conidiotns
  if (gameOver) {
    shots = false;
    stroke(255, 0, 0);
    drawGameOver(); 
    //sets all sprites to dead to remove them from game play
    missile.setDead(true); // this is so the player doesnt instantly kill an enemy or lose score if they restart too soon
    fireball.setDead(true);
    freezeShips.setDead(true);
    shieldIcon.setDead(true);
    speedUp.setDead(true);
    helperShip.setDead(true);
    helpPowerUp.setDead(true);
    // kill all monsters for the end screen 
    for (int idx = 0; idx < monsters.length; idx++) {
      Sprite monster = monsters[idx];
      monster.setDead(true);
    }
    // restart condition 
    if (kbController.isRestart()) {
      restartLevel("easy");
    } else if (kbController.isHellH() && kbController.isHellE() && kbController.isHellL()) {
      restartLevel("difficult");
    }
  }
  if (shots) {
    fireFireball();
    if (fireball.isDead())
      replaceFireMonster();
  }
  yOffset++;

  //respawns powerups after they go offscreen
  if (freezeShips.getY() > 500) {
    freezeShips.setDead(true);
    freezeShips = buildFreezeShips();
    randomizeFreezeShip();
  }

  if (shieldIcon.getY() > 500) {
    shieldIcon.setDead(true);
    shieldIcon = buildShield();
  }

  if (helpPowerUp.getY() > 500) {
    helpPowerUp.setDead(true);
    helpPowerUp = buildHelperPowerUp();
  }

  if (speedUp.getY() > 500) {
    speedUp.setDead(true);
    speedUp = buildSpeedUp();
  }

  //deactivates powerups after a certain amount of time has passed
  //also respawns powerups in a random region off screen 
  if (enemyShipsFreezed) {
    int currentTime = millis() - freezeTimer;
    if (currentTime >= timerDuration) {
      currentTime = 0;
      freezeTimer = 0;
      enemyShipsFreezed = false;
    }
  }

  if (shipInvincible) {
    int currentTime = millis() - shieldTimer;
    shieldBubble.setDead(false);
    shieldBubble.setPos(ship.getPos());
    if (currentTime >= timerDuration) {
      currentTime = 0;
      shieldTimer = 0;
      shipInvincible = false;
      shieldBubble.setDead(true);
    }
  }

  if (helperShipActive) {
    int currentTime = millis() - helperShipTimer;
    if (currentTime >= timerDuration) {
      currentTime = 0; 
      helperShipTimer = 0;
      helperShipActive = false;
      helperShip.setDead(true);
      ship.setDomain(0, height-ship.getHeight(), width, height, Sprite.HALT);
      helpPowerUp = buildHelperPowerUp();
    }
  }

  if (speedUpActive) {
    int currentTime = millis() - speedUpTimer;
    if (currentTime >= timerDuration) {
      currentTime = 0;
      speedUpTimer = 0;
      speedUpActive = false;
      speedUp = buildSpeedUp();
    }
  }

  S4P.drawSprites();
}

//methods to build sprites
void buildSprites() {
  // The Ships
  helperShip = buildHelperShip();
  ship = buildShip();
  // The Grid Monsters 
  buildMonsterGrid();
  missile = buildMissile();
  fireball = buildFireball();
  freezeShips = buildFreezeShips();
  speedUp = buildSpeedUp();
  shieldIcon = buildShield();
  helpPowerUp = buildHelperPowerUp();
  helperMissile = buildHelperMissile();
  randomizeFreezeShip();
}

//builds main ship
Sprite buildShip() {
  Sprite ship = new Sprite(this, "ship.png", 50);
  ship.setXY(width/2, height - 30);
  ship.setVelXY(0.0f, 0);
  ship.setScale(.75);
  ship.setRot(3.14159);
  // Domain keeps the moving sprite withing specific screen area 
  //if statement limits bounds even further to avoid colliding with helper ship
  if (helperShipActive) {
    ship.setDomain(helperShip.getWidth() + 20, height-ship.getHeight(), width - helperShip.getWidth() - 20, height, Sprite.HALT);
  } else {
    ship.setDomain(0, height-ship.getHeight(), width, height, Sprite.HALT);
  }
  return ship;
}

//builds powerup that freezes the ship
Sprite buildFreezeShips() {
  Sprite freezeShips = new Sprite(this, "freeze.png", 50);
  freezeShips.setScale(0.50);
  return freezeShips;
}

//builds shield icon 
Sprite buildShield() {
  Sprite shield = new Sprite(this, "shieldIcon.png", 50);
  shield.setDead(false);
  shield.setScale(0.4);
  shield.setXY(random(0, 700), random(-1200, -500));
  shield.setSpeed(fmSpeed, fmRightAngle);
  shield.setDomain(0, 0, width, height+100, Sprite.REBOUND);
  return shield;
}

//builds powerup that spawns a shield
Sprite buildSpeedUp() {
  Sprite speed = new Sprite(this, "speed.png", 50);
  speed.setDead(false);
  speed.setScale(0.25);
  speed.setXY(random(0, 700), random(-1200, -900));
  speed.setSpeed(fmSpeed, fmRightAngle);
  speed.setDomain(0, 0, width, height+100, Sprite.REBOUND);
  return speed;
}

//builds powerup that spawns a shield
Sprite buildShieldBubble() {
  Sprite shieldBubble = new Sprite(this, "shield.png", 50);
  shieldBubble.setDead(true);
  shieldBubble.setPos(ship.getPos());
  return shieldBubble;
}

//builds powerup that spawns in a helper ship
Sprite buildHelperPowerUp() {
  Sprite helper = new Sprite(this, "helperShip.png", 50);
  helper.setDead(false);
  helper.setScale(0.5);
  helper.setXY(random(0, 700), random(-1200, -800));
  helper.setSpeed(fmSpeed, fmRightAngle);
  helper.setDomain(0, 0, width, height+100, Sprite.REBOUND);
  return helper;
}

//this is a helper ship - spawned when missile collides with powerup
Sprite buildHelperShip() {
  Sprite ship = new Sprite(this, "ship.png", 50);
  ship.setScale(0.5);
  ship.setDead(true);
  ship.setXY(width/2 - ship.getWidth() - 20, height - 30);
  ship.setVelXY(0.0f, 0);
  ship.setRot(3.14159);
  ship.setDomain(0, height - ship.getHeight(), width - 150, height, Sprite.HALT);
  return ship;
}

//builds the missile for helper ship
Sprite buildHelperMissile() {
  Sprite missile = new Sprite(this, "rocket.png", 10);
  missile.setScale(0.25);
  missile.setDead(true);
  return missile;
}

// Build individual monster
Sprite buildMonster() {
  Sprite monster = new Sprite(this, "monster.png", 30);
  monster.setScale(.5);
  monster.setDead(false);
  return monster;
}

// Populate the monsters grid 
void buildMonsterGrid() {
  for (int idx = 0; idx < monsters.length; idx++ ) {
    monsters[idx] = buildMonster();
  }
}

//builds missile
Sprite buildMissile() {
  // The Missile
  Sprite sprite  = new Sprite(this, "rocket.png", 10); 
  sprite.setScale(.5); 
  sprite.setDead(true); // Initially hide the missile
  return sprite;
}

//builds fireball
Sprite buildFireball() {
  //for enemy fireball
  Sprite sprite = new Sprite(this, "fireball.png", 10);
  sprite.setScale(.5);
  sprite.setDead(true); // initallly no fireball will go
  return sprite;
}

//freezes all monsters
void freezeShips() {
  for (int idx = 0; idx < monsters.length; idx++) {
    monsters[idx].setSpeed(0, 0);
  }
  fireball.setDead(true);
}

// Arrange Monsters into a grid
void resetMonsters() {
  for (int idx = 0; idx < monsters.length; idx++ ) {
    Sprite monster = monsters[idx];
    monster.setSpeed(0, 0);
    double mwidth = monster.getWidth() + 20;
    double totalWidth = mwidth * monsterCols;
    double start = (width - totalWidth)/2 - 25;
    double mheight = monster.getHeight();
    int xpos = (int)((((idx % monsterCols)*mwidth)+start));
    int ypos = (int)(((int)(idx / monsterCols)*mheight)+50);
    monster.setXY(xpos, ypos);
    monster.setDead(false);
  }
}

//initializes arrays that store coordinates for stars
void initializeStars() {
  for (int i = 0; i < 5000; i++) {
    int x = (int)(random(700));
    int y = (int)(random(1200))-600;
    xStars[i] = x;
    yStars[i] = y;
  }
}

//draws the starry background
void drawStars() {
  for (int i = 0; i < 5000; i++) {
    if (yStars[i] + yOffset > 500) {
      yStars[i] = (int)(random(1200))- 1200 - yOffset;
    }
    point(xStars[i], yStars[i] + yOffset);
  }
}

//stops missile
void stopMissile(Sprite missileDestroy) {
  missileDestroy.setSpeed(0, upRadians); 
  missileDestroy.setDead(true);
}

//stops fireball
void stopFireball() {
  fireball.setSpeed(0, downRadians);
  fireball.setDead(true);
}

// Pick the first monster on the grid that is not dead.
// Return null if they are all dead.
Sprite pickNonDeadMonster() {
  for (int idx = 0; idx < monsters.length; idx++) {
    Sprite monster = monsters[idx]; 
    if (!monster.isDead() && monster != fireMonster) {
      shots = true;
      return monster;
    } else if (monster == fireMonster) {
      shots = false;
      fireMonster = null;
      return monster;
    }
  }
  return null;
}

//picks a random monster that isnt falling or dead
Sprite constpickNonDeadNonFallingMonster() {

  while (fireMonster == null) {
    shots = false; 
    int idxf = int(random(0, monsters.length));
    Sprite monster = monsters[idxf];
    if (!monster.isDead()) {
      shots = true;
      fireMonster = monsters[idxf];
      return monster;
    }
  }
  return null;
}

//code to fire missile when space bar is pressed
void fireMissile() {
  //main ship

  if (speedUpActive) {
    missileSpeed =  750;
  } 

  missileSpeed = speedUpActive ? 750 : 500;

  if (missile.isDead() && !ship.isDead()) {
    missile.setPos(ship.getPos()); 
    missile.setSpeed(missileSpeed, upRadians); 
    missile.setDead(false);
  }

  //helper ship - will only fire if helper ship is active
  if (helperShipActive) {
    if (helperMissile.isDead() && !helperShip.isDead()) {
      helperMissile.setPos(helperShip.getPos());
      helperMissile.setSpeed(missileSpeed, upRadians);
      helperMissile.setDead(false);
      println("Firing");
    }
  }
}

//fires fireballs
void fireFireball() {
  if (!enemyShipsFreezed) {
    if (fireMonster != null) {
      if (fireball.isDead()) {
        if (int(random(fireballTimer)) == 1) {
          fireball.setDead(false);
          score += 10; //debuggging
          fireball.setPos(fireMonster.getPos());
          fireball.setSpeed(random(fireballSpeed1, fireballSpeed2), downRadians);
        }
      }
    }
  }
}

//checks to see if any keys are pressed
void checkKeys() {
  if (focused) {
    if (kbController.isLeft()) {
      ship.setX(ship.getX()-10);
      helperShip.setX(helperShip.getX() - 10);
    }
    if (kbController.isRight()) {
      ship.setX(ship.getX()+10);
      helperShip.setX(helperShip.getX() + 10);
    }
    if (kbController.isSpace()) {
      fireMissile();
    }
  }
}

//moves grid of monsters across the screen
void moveMonsters() {  
  if (!enemyShipsFreezed) {
    // Move Grid Monsters and fire monster
    mmCounter++; 
    if ((mmCounter % 100) == 0) mmStep *= -1; 
    for (int idx = 0; idx < monsters.length; idx++ ) {
      Sprite monster = monsters[idx]; 
      if (!monster.isDead() && monster != fallingMonster) {
        monster.setXY(monster.getX()+mmStep, monster.getY());
      }
    }

    // Move Falling Monster
    if (fallingMonster != null) {
      if (int(random(difficulty)) == 1) {
        // Change FM Speed
        fallingMonster.setSpeed(fallingMonster.getSpeed() 
          + random(rndl, rndh)); // make it a bit harder
        // Reverse FM direction.
        if (fallingMonster.getDirection() == fmRightAngle) 
          fallingMonster.setDirection(fmLeftAngle); 
        else
          fallingMonster.setDirection(fmRightAngle);
      }
    }
  }
}

//randomizes direction of powerups
void randomizePowerUpMovement() {
  //randomizes the movement of the shield powerup
  if (shieldIcon != null) {
    if (int(random(difficulty)) == 1) {
      shieldIcon.setSpeed(shieldIcon.getSpeed() + random(rndl, rndh));
      if (shieldIcon.getDirection() == fmRightAngle) {
        shieldIcon.setDirection(fmLeftAngle);
      } else {
        shieldIcon.setDirection(fmRightAngle);
      }
    }
  }

  //randomizes the movement of the freeze powerup
  if (freezeShips != null) {
    if (int(random(difficulty)) == 1) {
      freezeShips.setSpeed(freezeShips.getSpeed() + random(rndl, rndh));
      if (freezeShips.getDirection() == fmRightAngle) {
        freezeShips.setDirection(fmLeftAngle);
      } else {
        freezeShips.setDirection(fmRightAngle);
      }
    }
  }

  //randomizes the movement of the helperShip powerup
  if (helpPowerUp != null) {
    if (int(random(difficulty)) == 1) {
      helpPowerUp.setSpeed(helpPowerUp.getSpeed() + random(rndl, rndh));
      if (helpPowerUp.getDirection() == fmRightAngle) {
        helpPowerUp.setDirection(fmLeftAngle);
      } else {
        helpPowerUp.setDirection(fmRightAngle);
      }
    }
  }

  //randomizes the movement of the speedUp powerup
  if (speedUp != null) {
    if (int(random(difficulty)) == 1) {
      speedUp.setSpeed(speedUp.getSpeed() + random(rndl, rndh));
      if (speedUp.getDirection() == fmRightAngle) {
        speedUp.setDirection(fmLeftAngle);
      } else {
        speedUp.setDirection(fmRightAngle);
      }
    }
  }
}

// Detect collisions between sprites
void processCollisions() {
  // Detect collisions between Grid Monsters and Missile
  for (int idx = 0; idx < monsters.length; idx++) {
    Sprite monster = monsters[idx]; 
    if (!missile.isDead() && !monster.isDead() 
      && monster != fallingMonster 
      && monster != fireMonster && missile.bb_collision(monster)) {
      monster.setDead(true); 
      if (monster == fireMonster) {
        replaceFireMonster();
      }
      //monster death sound
      soundPlayer.playInline(); 
      score += gridMonsterPts; 
      missile.setDead(true);
    }
  }

  // Between Falling Monster and Missile
  if (!missile.isDead() && fallingMonster != null 
    && missile.cc_collision(fallingMonster)) {
    shots = false;
    score += fallingMonsterPts; 
    //falling monster death sound
    fallingMonster.setDead(true); 
    missile.setDead(true);
    soundPlayer.playFlyer(); 
    fallingMonster = null;
    shots = true;
  }

  // Between Falling Monster and Ship
  if (!shipInvincible && fallingMonster!= null && !ship.isDead() 
    && fallingMonster.bb_collision(ship)) {
    explodeShip(ship); 
    fallingMonster.setDead(true); 
    fallingMonster = null; 
    gameOver = true;
  }

  //between fireball and ship
  if (!shipInvincible && fireball != null && !ship.isDead() && fireball.bb_collision(ship)) {
    shots = false;
    fireball.setXY(0, 0);
    explodeShip(ship);
    fireball.setDead(true);
    gameOver = true;
  }

  //between fireMonster and ship
  if (fireMonster != null && !missile.isDead() 
    && fireMonster.bb_collision(missile)) { 
    fireMonster.setDead(true); 
    fireMonster = null; 
    missile.setDead(true);
    soundPlayer.playInline();
    score += 10;
    if (fallingMonster != null) {
      replaceFireMonster();
    }
    fireball.setDead(true);
  }

  //between ship and freeze powerup
  if (!missile.isDead() && !freezeShips.isDead() && missile.cc_collision(freezeShips)) {
    freezeShips.setDead(true);
    missile.setDead(true);
    freezeTimer = millis();
    freezeShips();
    enemyShipsFreezed = true;
  }

  //between ship and shield powerup
  if (!missile.isDead() && !shieldIcon.isDead() && missile.cc_collision(shieldIcon)) {
    shieldIcon.setDead(true);
    missile.setDead(true);
    shieldTimer = millis();
    shipInvincible = true;
    shieldIcon = buildShield();
    shieldBubble = buildShieldBubble();
  }

  //between ship and helper ship powerup
  if (!missile.isDead() && !helpPowerUp.isDead() && missile.cc_collision(helpPowerUp)) {
    missile.setDead(true);
    helperShipTimer = millis();
    helperShipActive = true;
    helperShip.setDead(false);
    helpPowerUp.setDead(true);
    ship.setDomain(helperShip.getWidth() + 20, height - ship.getHeight(), width - helperShip.getWidth() - 20, height, Sprite.HALT);
    helperShip.setDomain(0, height - ship.getHeight(), width - 150, height, Sprite.HALT);
  } 

  //between ship and speed up powerup
  if (!missile.isDead() && !speedUp.isDead() && missile.cc_collision(speedUp)) {
    missile.setDead(true);
    speedUpTimer = millis();
    speedUpActive = true;
    speedUp.setDead(true);
  }

  //detect all collisions involving helper ship
  if (helperShipActive) {
    // Detect collisions between Grid Monsters and Helper missile
    for (int idx = 0; idx < monsters.length; idx++) {
      Sprite monster = monsters[idx]; 
      if (!helperMissile.isDead() && !monster.isDead() 
        && monster != fallingMonster 
        && monster != fireMonster && helperMissile.bb_collision(monster)) {
        monster.setDead(true); 
        if (monster == fireMonster) {
          replaceFireMonster();
        }
        //monster death sound
        soundPlayer.playInline(); 
        score += gridMonsterPts; 
        helperMissile.setDead(true);
      }
    }

    // Between Falling Monster and Missile
    if (!helperMissile.isDead() && fallingMonster != null 
      && helperMissile.cc_collision(fallingMonster)) {
      shots = false;
      score += fallingMonsterPts; 
      //falling monster death sound
      fallingMonster.setDead(true); 
      helperMissile.setDead(true);
      soundPlayer.playFlyer(); 
      fallingMonster = null;
      shots = true;
    }

    // Between Falling Monster and Ship
    if (fallingMonster!= null && !helperShip.isDead() 
      && fallingMonster.bb_collision(helperShip)) {
      explodeShip(helperShip);
      ship.setDomain(0, height-ship.getHeight(), width, height, Sprite.HALT);
      helperShipActive = false;
      fallingMonster.setDead(true); 
      fallingMonster = null;
    }

    //between fireball and helper ship
    if (fireball != null && !helperShip.isDead() && fireball.bb_collision(helperShip)) {
      shots = false;
      fireball.setXY(0, 0);
      explodeShip(helperShip);
      ship.setDomain(0, height-ship.getHeight(), width, height, Sprite.HALT);
      fireball.setDead(true);
    }

    //between fireMonster and ship
    if (fireMonster != null && !helperMissile.isDead() 
      && fireMonster.bb_collision(helperMissile)) { 
      fireMonster.setDead(true); 
      fireMonster = null; 
      helperMissile.setDead(true);
      soundPlayer.playInline();
      score += 10;
      if (fallingMonster != null) {
        replaceFireMonster();
      }
      fireball.setDead(true);
    }
  } // end of outer if statement
}

//randomizes the location of freeze power up
void randomizeFreezeShip() {
  if (!enemyShipsFreezed) {
    freezeShips.setDead(false);
    freezeShips.setXY(random(0, 700), random(-800, -500));
    freezeShips.setSpeed(fmSpeed, fmRightAngle);
    freezeShips.setDomain(0, 0, width, height+100, Sprite.REBOUND);
  }
}

//replaces falling monster
void replaceFallingMonster() { 
  if (!enemyShipsFreezed) {
    if (fallingMonster != null) {
      fallingMonster.setDead(true); 
      score -= fallingGotAway; // this is if the monster fell of screen and was not kill so the player gets docked 50 points
      fallingMonster = null;
    }

    // select new falling monster 
    fallingMonster = pickNonDeadMonster(); 
    if (fallingMonster == null) {
      return;
    }

    fallingMonster.setSpeed(fmSpeed, fmRightAngle); 
    // Domain keeps the moving sprite within specific screen area 
    fallingMonster.setDomain(0, 0, width, height+100, Sprite.REBOUND);
  }
}

//replaces fire monster
void replaceFireMonster() {
  fireball.setDead(true);
  fireMonster = constpickNonDeadNonFallingMonster();
}

//plays the destroys ship sprite after ship dies
void explodeShip(Sprite deadShip) {
  soundPlayer.playExplosion(); 
  explosion.setPos(deadShip.getPos()); 
  explosion.setFrameSequence(0, 16, 0.1, 1); 
  deadShip.setDead(true);
}

//draws the score at the top
void drawScore() {
  textSize(32); 
  String msg = " Score: " + score; 
  text(msg, 10, 30);
}

//draws game over sprite
void drawGameOver() {
  gameOverSprite.setXY(width/2, height/2); 
  gameOverSprite.setDead(false);
  String high = "High score: " + highscore;
  text(high, 200, 30);
}

//code to restart the game
void restartGame() {
  //default values for game restart
  fallingMonster = null;
  resetMonsters();
  score = 0;
  gameOverSprite.setDead(true);
  ship.setDead(false);
  freezeShips = buildFreezeShips();
  randomizeFreezeShip();
  shieldIcon = buildShield();
  helpPowerUp = buildHelperPowerUp();
  speedUp = buildSpeedUp();
  shots = true;
  gameOver = false;
  mmCounter = 0;
  mmStep = 1;
}

//sets values for game based on difficulty level
void restartLevel(String hardLevel) {

  //sets game values based on level of difficulty the user chooses
  restartGame();
  gameMode = hardLevel.equals("difficult") ? false : true;
  fallingMonsterPts = hardLevel.equals("difficult") ? 40 : 20;
  gridMonsterPts = hardLevel.equals("difficult") ? 20 : 10;
  missedShot = hardLevel.equals("difficult") ? 10 : 5;
  fallingGotAway = hardLevel.equals("difficult") ? 60 : 50;
  clearedScreen = hardLevel.equals("difficult") ? 200 : 100;
  fireballTimer = hardLevel.equals("difficult") ? 10 : 50;
  rndl = hardLevel.equals("difficult") ? 10 : -20;
  rndh = hardLevel.equals("difficult") ? 80 : 70;
  difficulty = hardLevel.equals("difficult") ? 25 : 100;
  timerDuration = hardLevel.equals("difficult") ? 5000 : 10000;
}
