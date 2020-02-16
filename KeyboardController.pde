
import org.gamecontrolplus.*;
import net.java.games.input.*;

class KeyboardController {

  ControlIO controllIO;
  ControlDevice keyboard;
  ControlButton spaceBtn, leftArrow, rightArrow, downArrow, restartT, hellModeH, hellModeE, hellModeL;

  KeyboardController(PApplet applet) {
    controllIO = ControlIO.getInstance(applet);
    keyboard = controllIO.getDevice("Keyboard");
    spaceBtn = keyboard.getButton("Space");   
    leftArrow = keyboard.getButton("Left");   
    rightArrow = keyboard.getButton("Right");
    downArrow = keyboard.getButton("Down");
    restartT = keyboard.getButton("R");
    hellModeH = keyboard.getButton("H"); 
    hellModeE = keyboard.getButton("E");
    hellModeL = keyboard.getButton("L");
  }

  boolean isDown() {
    return downArrow.pressed();
  }

  boolean isLeft() {
    return leftArrow.pressed();
  }

  boolean isRight() {
    return rightArrow.pressed();
  }

  boolean isSpace() {
    return spaceBtn.pressed();
  }

  boolean isRestart() {
    return restartT.pressed();
  }

  boolean isHellH() {
    return hellModeH.pressed();
  }

  boolean isHellE() {
    return hellModeE.pressed();
  }

  boolean isHellL() {
    return hellModeL.pressed();
  }
}
