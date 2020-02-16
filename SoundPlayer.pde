
import ddf.minim.*; // Import Sound Library

class SoundPlayer {
  Minim minimplay;
  AudioSample boomPlayer, flyerPlayer, inlinePlayer;

  SoundPlayer(Object app) {
    minimplay = new Minim(app); 
    boomPlayer = minimplay.loadSample("explode.wav", 1024); 
    flyerPlayer = minimplay.loadSample("flyer.wav", 1024);
    inlinePlayer = minimplay.loadSample("inline.wav", 1024);
  }

  void playExplosion() {
    boomPlayer.trigger();
  }

  void playFlyer() {
    flyerPlayer.trigger();
  }
  void playInline() {
    inlinePlayer.trigger();
  }
}
