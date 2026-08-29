// Audio Alert System for Snooze Lost PWA
// Level 1 (warning) = เสียงเบา + สั่น
// Level 3 (danger) = เสียงดังแบบแจ้งเตือนแผ่นดินไหว
 
let audioCtx = null;
let dangerInterval = null;
 
function getAudioContext() {
  if (!audioCtx) {
    audioCtx = new (window.AudioContext || window.webkitAudioContext)();
  }
  return audioCtx;
}
 
// Level 1: Warning — เสียงเตือนเบาๆ + สั่น
function playWarningAlert() {
  try {
    stopDangerAlert(); // หยุด danger ก่อนถ้าเปิดอยู่
 
    const ctx = getAudioContext();
    const oscillator = ctx.createOscillator();
    const gainNode = ctx.createGain();
 
    oscillator.connect(gainNode);
    gainNode.connect(ctx.destination);
 
    oscillator.type = 'sine';
    oscillator.frequency.setValueAtTime(880, ctx.currentTime);
    oscillator.frequency.exponentialRampToValueAtTime(440, ctx.currentTime + 0.3);
 
    gainNode.gain.setValueAtTime(0.3, ctx.currentTime);
    gainNode.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.5);
 
    oscillator.start(ctx.currentTime);
    oscillator.stop(ctx.currentTime + 0.5);
 
    // สั่น (ถ้า browser รองรับ)
    if (navigator.vibrate) {
      navigator.vibrate([200, 100, 200]);
    }
  } catch (e) {
    console.error('Warning alert error:', e);
  }
}
 
// Level 3: Danger — เสียงดังแบบแผ่นดินไหว ดังซ้ำๆ
function playDangerAlert() {
  try {
    stopDangerAlert(); // หยุดอันเก่าก่อน
 
    const ctx = getAudioContext();
 
    function playOneBurst() {
      // เสียง burst แรก (ความถี่สูง)
      const osc1 = ctx.createOscillator();
      const gain1 = ctx.createGain();
      osc1.connect(gain1);
      gain1.connect(ctx.destination);
      osc1.type = 'square';
      osc1.frequency.setValueAtTime(1200, ctx.currentTime);
      osc1.frequency.exponentialRampToValueAtTime(600, ctx.currentTime + 0.15);
      gain1.gain.setValueAtTime(0.8, ctx.currentTime);
      gain1.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.15);
      osc1.start(ctx.currentTime);
      osc1.stop(ctx.currentTime + 0.15);
 
      // เสียง burst สอง (ต่ำลง)
      const osc2 = ctx.createOscillator();
      const gain2 = ctx.createGain();
      osc2.connect(gain2);
      gain2.connect(ctx.destination);
      osc2.type = 'square';
      osc2.frequency.setValueAtTime(600, ctx.currentTime + 0.2);
      osc2.frequency.exponentialRampToValueAtTime(300, ctx.currentTime + 0.35);
      gain2.gain.setValueAtTime(0.8, ctx.currentTime + 0.2);
      gain2.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.35);
      osc2.start(ctx.currentTime + 0.2);
      osc2.stop(ctx.currentTime + 0.35);
 
      // สั่นแรงๆ
      if (navigator.vibrate) {
        navigator.vibrate([400, 100, 400, 100, 400]);
      }
    }
 
    playOneBurst();
    // วนซ้ำทุก 1 วินาที
    dangerInterval = setInterval(playOneBurst, 1000);
 
  } catch (e) {
    console.error('Danger alert error:', e);
  }
}
 
// หยุดเสียง danger
function stopDangerAlert() {
  if (dangerInterval) {
    clearInterval(dangerInterval);
    dangerInterval = null;
  }
  if (navigator.vibrate) {
    navigator.vibrate(0); // หยุดสั่น
  }
}
 
// Expose ให้ Flutter เรียกได้
window.playWarningAlert = playWarningAlert;
window.playDangerAlert = playDangerAlert;
window.stopDangerAlert = stopDangerAlert;