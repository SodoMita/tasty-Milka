"use client";

import { useEffect, useMemo, useRef, useState } from "react";

type Phase =
  | "title"
  | "intro"
  | "ask-name"
  | "name-input"
  | "greet"
  | "rhythm-intro"
  | "rhythm"
  | "rhythm-result"
  | "ending";

type MilkaMood = "neutral" | "smile" | "surprised" | "worried" | "happy" | "thinking" | "celebrate";

interface DialogueLine {
  who: "milka" | "narrator";
  text: string;
  mood?: MilkaMood;
}

// ---------- Milka character SVG ----------
function MilkaSprite({ mood, animClass = "" }: { mood: MilkaMood; animClass?: string }) {
  // simple cute cow-girl-ish milkmaid cat? We'll do a chibi SVG character.
  // Ears: cow spots? Milka-chan from VN is a cat girl with milk theme.
  const eyeShape =
    mood === "surprised"
      ? { rx: 6, ry: 8 }
      : mood === "worried"
      ? { rx: 5, ry: 2 }
      : mood === "happy" || mood === "celebrate"
      ? { rx: 6, ry: 1 }
      : { rx: 4, ry: 5 };
  const mouth =
    mood === "happy" || mood === "celebrate"
      ? "M 85 130 Q 100 148 115 130"
      : mood === "worried"
      ? "M 88 135 Q 100 128 112 135"
      : mood === "surprised"
      ? "M 96 132 Q 100 142 104 132 Q 100 138 96 132 Z"
      : mood === "thinking"
      ? "M 90 134 Q 100 130 110 136"
      : "M 92 132 Q 100 140 108 132";
  const cheekColor = mood === "celebrate" || mood === "happy" ? "#ff9fb3" : "#ffc3d0";
  const ears = mood === "surprised" ? -10 : mood === "worried" ? -4 : -6;

  return (
    <div className={`relative ${animClass}`}>
      <svg viewBox="0 0 200 260" width="200" height="260" className="drop-shadow-xl">
        {/* hair back */}
        <path d="M 50 90 Q 40 200 70 240 L 130 240 Q 160 200 150 90 Z" fill="#f7e6d0" />
        {/* cat ears */}
        <path d={`M 60 90 L 70 ${55 + ears} L 90 85 Z`} fill="#f7e6d0" />
        <path d={`M 140 90 L 130 ${55 + ears} L 110 85 Z`} fill="#f7e6d0" />
        <path d={`M 67 83 L 72 ${65 + ears} L 82 82 Z`} fill="#ffc3d0" />
        <path d={`M 133 83 L 128 ${65 + ears} L 118 82 Z`} fill="#ffc3d0" />
        {/* head */}
        <ellipse cx="100" cy="105" rx="48" ry="52" fill="#fff8ef" />
        {/* cow spots on face? subtle */}
        <ellipse cx="72" cy="88" rx="8" ry="6" fill="#e6c89f" opacity="0.55" />
        <ellipse cx="125" cy="95" rx="6" ry="5" fill="#e6c89f" opacity="0.4" />
        {/* bangs */}
        <path d="M 55 80 Q 65 55 100 55 Q 135 58 145 85 Q 130 75 115 78 Q 105 70 92 78 Q 72 72 55 88 Z" fill="#f0d9b5" />
        {/* ahoge */}
        <path d="M 100 55 Q 108 35 115 45 Q 108 48 103 60 Z" fill="#a87a4a" />
        {/* eyes */}
        <ellipse cx="82" cy="110" rx={eyeShape.rx} ry={eyeShape.ry} fill="#3a2a1f" />
        <ellipse cx="118" cy="110" rx={eyeShape.rx} ry={eyeShape.ry} fill="#3a2a1f" />
        {eyeShape.ry > 2 && (
          <>
            <circle cx="84" cy="108" r="2" fill="white" />
            <circle cx="120" cy="108" r="2" fill="white" />
          </>
        )}
        {/* cheeks */}
        <circle cx="73" cy="127" r="6" fill={cheekColor} opacity="0.7" />
        <circle cx="127" cy="127" r="6" fill={cheekColor} opacity="0.7" />
        {/* mouth */}
        <path d={mouth} stroke="#8b5a3c" strokeWidth="2.5" fill={mood === "surprised" ? "#c96a7f" : "none"} strokeLinecap="round" />
        {/* body/overalls */}
        <path d="M 60 170 Q 100 155 140 170 L 150 250 Q 100 260 50 250 Z" fill="#fff5e6" />
        {/* milky apron/shirt */}
        <path d="M 70 175 Q 100 168 130 175 L 132 230 Q 100 238 68 230 Z" fill="#ffffff" stroke="#e0c9a7" strokeWidth="2" />
        {/* milk droplet on apron */}
        <path d="M 100 195 Q 93 212 100 220 Q 107 212 100 195 Z" fill="#f0f7ff" stroke="#b0d4ff" strokeWidth="1.5" />
        {/* arms */}
        <ellipse cx="55" cy="210" rx="12" ry="25" fill="#fff8ef" />
        <ellipse cx="145" cy="210" rx="12" ry="25" fill="#fff8ef" />
        {/* tail hint */}
        {mood === "celebrate" && (
          <g>
            <path d="M 160 220 Q 185 200 180 175" stroke="#f7e6d0" strokeWidth="8" fill="none" strokeLinecap="round" />
            <circle cx="180" cy="173" r="7" fill="#fff8ef" />
          </g>
        )}
      </svg>
      {mood === "celebrate" && (
        <>
          <span className="absolute top-2 right-2 text-2xl" style={{ animation: "sparkle 1.2s ease-in-out infinite" }}>✨</span>
          <span className="absolute top-10 left-2 text-xl" style={{ animation: "sparkle 1.2s ease-in-out infinite 0.3s" }}>✨</span>
          <span className="absolute bottom-10 right-0 text-xl" style={{ animation: "sparkle 1.2s ease-in-out infinite 0.6s" }}>🥛</span>
        </>
      )}
    </div>
  );
}

// ---------- Name validation ----------
interface NameIssue {
  type: "lowercase-start" | "has-numbers" | "emoji" | "math" | "special" | "space-inside" | "too-long" | "empty" | "okay";
  label: string;
}

function analyzeName(name: string): NameIssue[] {
  const issues: NameIssue[] = [];
  const trimmed = name.trim();
  if (!trimmed) {
    issues.push({ type: "empty", label: "is empty" });
    return issues;
  }
  if (trimmed.length > 16) issues.push({ type: "too-long", label: "is way too long for a little cow-girl like me to remember~" });
  if (!/^[A-ZÀ-ÝА-Я]/.test(trimmed)) {
    issues.push({ type: "lowercase-start", label: "doesn't start with a capital letter" });
  }
  if (/\d/.test(trimmed)) issues.push({ type: "has-numbers", label: "has numbers in it" });
  // emoji ranges
  if (/[\p{Emoji_Presentation}\p{Extended_Pictographic}]/u.test(trimmed)) {
    issues.push({ type: "emoji", label: "has emoji in it — I can't emote that with my mouth full of milk!" });
  }
  // math symbols
  if (/[+\-*/=^%<>≤≥≈≠∑∫π∞√]/.test(trimmed)) {
    issues.push({ type: "math", label: "has math symbols — I'm a simple milk cow, not a calculator!" });
  }
  // other special chars (allow letters, apostrophes, hyphens, spaces; flag rest)
  if (/[^\p{L}\p{M}\s'\-]/u.test(trimmed) && !/[\d\p{Emoji_Presentation}\p{Extended_Pictographic}+\-*/=^%<>≤≥≈≠∑∫π∞√]/u.test(trimmed)) {
    // there's a symbol not covered above; refine
  }
  if (/[!@#$&()_[\]{};:"\\|,./?~`]/.test(trimmed)) {
    issues.push({ type: "special", label: `has weird symbols — did a cat walk on your keyboard?` });
  }
  return issues;
}

function milkaReaction(issues: NameIssue[]): DialogueLine[] {
  if (issues.length === 0) {
    return [
      { who: "milka", text: "Oh what a lovely name! It sounds so sparkly~ ✨", mood: "happy" },
    ];
  }
  const lines: DialogueLine[] = [{ who: "milka", text: "Eeeh? Wait a second,", mood: "surprised" }];
  issues.forEach((iss) => {
    switch (iss.type) {
      case "empty":
        lines.push({ who: "milka", text: "Y-you didn't type anything! Don't leave me hanging with a silent 'moo'! 🥛", mood: "worried" });
        break;
      case "too-long":
        lines.push({ who: "milka", text: "That name is longer than the list of cow treats I want today... I'll forget it halfway! Please shorten it?", mood: "worried" });
        break;
      case "lowercase-start":
        lines.push({ who: "milka", text: "Your name doesn't start with a capital letter! Are you feeling lowercase today? Should I moo in small letters too?", mood: "thinking" });
        break;
      case "has-numbers":
        lines.push({ who: "milka", text: "N-numbers? Are you a secret agent? Model-07? Is this a test?!", mood: "surprised" });
        break;
      case "emoji":
        lines.push({ who: "milka", text: "There's an emoji there! I can't pronounce sparkles with my mouth! My tongue isn't a Unicode engine! 🐄", mood: "worried" });
        break;
      case "math":
        lines.push({ who: "milka", text: "Math?! Please no, I already failed hay arithmetic in cow school! 2 + 2 = moo, right?", mood: "worried" });
        break;
      case "special":
        lines.push({ who: "milka", text: "That has weird symbols! Is that a spell? Are you trying to turn me into chocolate milk?!", mood: "surprised" });
        break;
      default:
        lines.push({ who: "milka", text: "Hmm, something about that name feels funny...", mood: "thinking" });
    }
  });
  lines.push({ who: "milka", text: "Wanna try again? Tap the input and fix it for me, please! 🥛", mood: "smile" });
  return lines;
}

// ---------- Dialogue box ----------
function DialogueBox({ line, onAdvance, typing }: { line: DialogueLine; onAdvance: () => void; typing?: boolean }) {
  const nameTag = line.who === "milka" ? "Milka-chan" : "Narrator";
  const bg = line.who === "milka" ? "bg-white/95 border-[#c9a27a]" : "bg-[#2a1f15]/85 border-[#2a1f15] text-white";
  return (
    <button
      onClick={onAdvance}
      className={`relative w-full max-w-3xl rounded-2xl border-4 ${bg} px-6 py-4 text-left shadow-2xl anim-float-up`}
    >
      <div className="mb-2 text-xs font-bold uppercase tracking-widest opacity-70">{nameTag}</div>
      <div className="milka-speech text-lg leading-relaxed min-h-[4.5rem]">
        {line.text}
        {typing && <span className="ml-1 animate-pulse">🐾</span>}
      </div>
      <div className="mt-2 text-right text-xs opacity-60">
        click / press <kbd className="rounded bg-black/10 px-1 py-0.5">Space</kbd> to continue ▸
      </div>
    </button>
  );
}

// ---------- Rhythm minigame ----------
type Note = {
  id: number;
  lane: 0 | 1 | 2 | 3;
  time: number; // ms from start
  hit: boolean | "miss";
  type?: "tap" | "slide";
  slideDir?: "left" | "right";
};

const LANE_KEYS = ["d", "f", "j", "k"] as const;
const LANE_COLORS = ["#ff9fb3", "#ffd59f", "#b0e57c", "#9fd5ff"];
const HIT_WINDOW_TAP = 180; // ms
const HIT_WINDOW_SLIDE = 260;

function RhythmGame({ onFinish }: { onFinish: (score: number, total: number, combo: number) => void }) {
  const [notes, setNotes] = useState<Note[]>([]);
  const [running, setRunning] = useState(false);
  const [score, setScore] = useState(0);
  const [combo, setCombo] = useState(0);
  const [maxCombo, setMaxCombo] = useState(0);
  const [feedback, setFeedback] = useState<{ lane: number; text: string; color: string; id: number } | null>(null);
  const [progress, setProgress] = useState(0);
  const [slidePrompt, setSlidePrompt] = useState<{ id: number; lane: number; dir: "left" | "right" } | null>(null);
  const startRef = useRef<number>(0);
  const rafRef = useRef<number | null>(null);
  const totalNotesRef = useRef(0);
  const activePointers = useRef<Map<number, { startX: number; lane: number; noteId: number }>>(new Map());

  // Generate pattern
  const pattern = useMemo<Note[]>(() => {
    const arr: Note[] = [];
    let t = 1500;
    let id = 0;
    const durations = [320, 300, 280, 260, 240, 220, 200, 220, 240, 260, 280, 320, 360];
    let laneSeq = [0, 1, 2, 3, 1, 2, 0, 3, 2, 1, 3, 0, 3, 2, 1, 0, 2, 3, 1, 0, 2, 1, 3, 0];
    for (let i = 0; i < laneSeq.length; i++) {
      const isSlide = i > 3 && i % 5 === 0;
      arr.push({
        id: id++,
        lane: laneSeq[i] as 0 | 1 | 2 | 3,
        time: t,
        hit: false,
        type: isSlide ? "slide" : "tap",
        slideDir: isSlide ? (Math.random() < 0.5 ? "left" : "right") : undefined,
      });
      t += durations[i % durations.length];
    }
    totalNotesRef.current = arr.length;
    return arr;
  }, []);

  const SONG_LEN = pattern[pattern.length - 1].time + 1500;

  useEffect(() => {
    setNotes(pattern.map((n) => ({ ...n, hit: false })));
  }, [pattern]);

  useEffect(() => {
    if (!running) return;
    startRef.current = performance.now();
    const loop = (now: number) => {
      const elapsed = now - startRef.current;
      setProgress(Math.min(1, elapsed / SONG_LEN));
      // Auto-miss expired notes
      setNotes((prev) => {
        let missTriggered = false;
        const next = prev.map((n) => {
          if (n.hit === false && elapsed > n.time + (n.type === "slide" ? HIT_WINDOW_SLIDE : HIT_WINDOW_TAP) + 200) {
            missTriggered = true;
            return { ...n, hit: "miss" as const };
          }
          return n;
        });
        if (missTriggered) {
          setCombo(0);
        }
        return next;
      });
      if (elapsed < SONG_LEN) {
        rafRef.current = requestAnimationFrame(loop);
      } else {
        // finalize
        setRunning(false);
        setTimeout(() => {
          const hitCount = notes.filter((n) => n.hit === true).length;
          onFinish(hitCount, totalNotesRef.current, maxCombo);
        }, 500);
      }
    };
    rafRef.current = requestAnimationFrame(loop);
    return () => {
      if (rafRef.current) cancelAnimationFrame(rafRef.current);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [running]);

  function hitCheck(lane: number, kind: "tap" | "slide") {
    const now = performance.now() - startRef.current;
    setNotes((prev) => {
      // find nearest unhit note in this lane
      let bestIdx = -1;
      let bestDiff = Infinity;
      for (let i = 0; i < prev.length; i++) {
        const n = prev[i];
        if (n.hit !== false || n.lane !== lane) continue;
        const win = n.type === "slide" ? HIT_WINDOW_SLIDE : HIT_WINDOW_TAP;
        if (n.type !== kind) continue;
        const diff = Math.abs(now - n.time);
        if (diff < win && diff < bestDiff) {
          bestDiff = diff;
          bestIdx = i;
        }
      }
      if (bestIdx === -1) return prev;
      const newNotes = [...prev];
      newNotes[bestIdx] = { ...newNotes[bestIdx], hit: true };
      let judge = "PERFECT";
      let color = "#ffdf6b";
      let add = 100;
      if (bestDiff > 100) {
        judge = "GOOD";
        color = "#b0e57c";
        add = 60;
      }
      if (bestDiff > 180) {
        judge = "OK";
        color = "#9fd5ff";
        add = 30;
      }
      setScore((s) => s + add + Math.min(combo, 30) * 2);
      setCombo((c) => {
        const nc = c + 1;
        setMaxCombo((m) => Math.max(m, nc));
        return nc;
      });
      setFeedback({ lane, text: judge, color, id: Date.now() });
      setTimeout(() => setFeedback(null), 400);
      return newNotes;
    });
  }

  function missSlide(lane: number) {
    setCombo(0);
    setFeedback({ lane, text: "MISS", color: "#ff7a7a", id: Date.now() });
    setTimeout(() => setFeedback(null), 400);
  }

  // keyboard controls
  useEffect(() => {
    if (!running) return;
    const down = (e: KeyboardEvent) => {
      const k = e.key.toLowerCase();
      if (LANE_KEYS.includes(k as any)) {
        e.preventDefault();
        const lane = LANE_KEYS.indexOf(k as any);
        // check if it's a slide or tap — but keyboard can tap; slides need arrow keys? Accept taps on both, but slides require a follow-up
        hitCheck(lane, "tap");
      }
      // arrow keys for sliding? we also use mouse/touch drag. For keyboard we accept taps on slides too as OK.
    };
    window.addEventListener("keydown", down);
    return () => window.removeEventListener("keydown", down);
  }, [running]);

  // Pointer: for click we do tap; for drag across a lane we trigger slide
  const laneRefs = useRef<(HTMLDivElement | null)[]>([]);
  function onLanePointerDown(e: React.PointerEvent, lane: number) {
    if (!running) return;
    const target = e.currentTarget as HTMLDivElement;
    target.setPointerCapture(e.pointerId);
    // check if there's an active slide note about to hit
    const now = performance.now() - startRef.current;
    activePointers.current.set(e.pointerId, { startX: e.clientX, lane, noteId: -1 });
    // attempt tap first
    hitCheck(lane, "tap");
    // check if slide note near
    const slideNote = notes.find(
      (n) => n.lane === lane && n.type === "slide" && n.hit === false && Math.abs(now - n.time) < HIT_WINDOW_SLIDE,
    );
    if (slideNote) {
      setSlidePrompt({ id: slideNote.id, lane, dir: slideNote.slideDir! });
    }
  }
  function onLanePointerMove(e: React.PointerEvent, lane: number) {
    if (!running) return;
    const info = activePointers.current.get(e.pointerId);
    if (!info) return;
    const dx = e.clientX - info.startX;
    if (Math.abs(dx) > 40) {
      // slide detected in lane
      if (slidePrompt && slidePrompt.lane === lane) {
        const correct =
          (slidePrompt.dir === "right" && dx > 40) || (slidePrompt.dir === "left" && dx < -40);
        if (correct) {
          hitCheck(lane, "slide");
        } else {
          missSlide(lane);
        }
        setSlidePrompt(null);
      }
      activePointers.current.delete(e.pointerId);
    }
  }
  function onLanePointerUp(e: React.PointerEvent, lane: number) {
    activePointers.current.delete(e.pointerId);
    setSlidePrompt(null);
  }

  return (
    <div className="relative w-full max-w-3xl select-none">
      {!running ? (
        <div className="flex flex-col items-center gap-4 rounded-2xl bg-white/90 p-6 shadow-xl border-4 border-[#c9a27a]">
          <p className="text-center milka-speech text-lg">
            🥛 Milka&apos;s Milky Mix 🥛<br />
            Tap <b>D F J K</b> when notes reach the bottom line!<br />
            For <b>slide notes</b> (longer arrows), click and drag left/right!
          </p>
          <button
            className="pixel-btn rounded-xl bg-[#ffb4c9] px-6 py-3 text-lg font-bold text-white shadow-lg anim-pulse-glow"
            onClick={() => {
              setScore(0);
              setCombo(0);
              setMaxCombo(0);
              setNotes(pattern.map((n) => ({ ...n, hit: false })));
              setRunning(true);
            }}
          >
            Start the beat! ▶
          </button>
        </div>
      ) : (
        <div className="relative h-[480px] w-full overflow-hidden rounded-2xl bg-gradient-to-b from-[#2b1d36] via-[#3a2a4d] to-[#4a2f4e] shadow-2xl border-4 border-[#c9a27a]">
          {/* progress bar */}
          <div className="absolute top-0 left-0 h-1 bg-[#ffd59f]" style={{ width: `${progress * 100}%` }} />
          {/* score */}
          <div className="absolute left-3 top-3 z-20 text-white font-mono">
            <div className="text-sm opacity-70">SCORE</div>
            <div className="text-2xl font-bold">{score}</div>
          </div>
          <div className="absolute right-3 top-3 z-20 text-white font-mono text-right">
            <div className="text-sm opacity-70">COMBO</div>
            <div className="text-2xl font-bold">{combo}x</div>
          </div>

          {/* lanes */}
          <div className="absolute inset-0 flex pt-10">
            {[0, 1, 2, 3].map((lane) => (
              <div
                key={lane}
                ref={(el) => {
                  laneRefs.current[lane] = el;
                }}
                onPointerDown={(e) => onLanePointerDown(e, lane)}
                onPointerMove={(e) => onLanePointerMove(e, lane)}
                onPointerUp={(e) => onLanePointerUp(e, lane)}
                onPointerCancel={(e) => onLanePointerUp(e, lane)}
                className="relative flex-1 border-x border-white/10 touch-none"
                style={{ background: `linear-gradient(to bottom, ${LANE_COLORS[lane]}10, transparent 30%)` }}
              >
                {/* hit line */}
                <div className="absolute bottom-14 left-0 right-0 h-1 bg-white/60 shadow-[0_0_10px_rgba(255,255,255,0.6)]" />
                {/* key hint */}
                <div
                  className="absolute bottom-2 left-1/2 -translate-x-1/2 h-10 w-10 rounded-lg flex items-center justify-center font-bold text-white/80 text-lg"
                  style={{ background: `${LANE_COLORS[lane]}40`, border: `2px solid ${LANE_COLORS[lane]}` }}
                >
                  {LANE_KEYS[lane].toUpperCase()}
                </div>

                {/* slide prompt arrow */}
                {slidePrompt?.lane === lane && (
                  <div
                    className="absolute bottom-20 left-1/2 -translate-x-1/2 text-3xl"
                    style={{
                      color: "#ffdf6b",
                      animation: "slide-swell 0.5s ease-in-out infinite",
                    }}
                  >
                    {slidePrompt.dir === "left" ? "⬅⬅ SWIPE" : "SWIPE ➡➡"}
                  </div>
                )}

                {/* feedback */}
                {feedback?.lane === lane && (
                  <div
                    key={feedback.id}
                    className="absolute bottom-24 left-1/2 -translate-x-1/2 text-xl font-bold"
                    style={{ color: feedback.color, textShadow: "0 0 8px rgba(0,0,0,0.8)" }}
                  >
                    {feedback.text}
                  </div>
                )}
              </div>
            ))}
          </div>

          {/* notes */}
          {notes.map((n) => {
            if (n.hit === true || n.hit === "miss") {
              // still show for a moment? hide
              return null;
            }
            const now = performance.now() - startRef.current;
            const travelMs = 2000;
            const delta = n.time - now;
            if (delta > travelMs) return null;
            const posPct = 100 - (delta / travelMs) * 100;
            const isSlide = n.type === "slide";
            return (
              <div
                key={n.id}
                className="absolute flex items-center justify-center"
                style={{
                  left: `${n.lane * 25 + 12.5}%`,
                  top: `calc(${posPct}% - 24px)`,
                  transform: "translateX(-50%)",
                  width: isSlide ? 88 : 52,
                  height: isSlide ? 28 : 52,
                  pointerEvents: "none",
                }}
              >
                <div
                  className="w-full h-full rounded-full shadow-lg"
                  style={{
                    background: isSlide
                      ? `linear-gradient(90deg, ${LANE_COLORS[n.lane]}, #fff, ${LANE_COLORS[n.lane]})`
                      : LANE_COLORS[n.lane],
                    border: isSlide ? "3px solid #ffdf6b" : "3px solid white",
                    boxShadow: `0 0 12px ${LANE_COLORS[n.lane]}`,
                  }}
                >
                  {isSlide && (
                    <div className="w-full h-full flex items-center justify-center text-xs font-bold text-[#3a2a1f]">
                      {n.slideDir === "left" ? "◀ SLIDE" : "SLIDE ▶"}
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

// ---------- Main app ----------
export default function MilkaGame() {
  const [phase, setPhase] = useState<Phase>("title");
  const [mood, setMood] = useState<MilkaMood>("neutral");
  const [nameValue, setNameValue] = useState("");
  const [playerName, setPlayerName] = useState("traveler");
  const [currentLine, setCurrentLine] = useState(0);
  const [issues, setIssues] = useState<NameIssue[]>([]);
  const [rhythmResult, setRhythmResult] = useState<{ score: number; total: number; max: number } | null>(null);
  const [animClass, setAnimClass] = useState("anim-bob");
  const [typewriter, setTypewriter] = useState("");
  const typingTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Helper: generate dialogue script per phase
  const script: Record<Phase, DialogueLine[]> = useMemo(() => {
    const niceName = playerName || "traveler";
    return {
      title: [],
      intro: [
        { who: "narrator", text: "Welcome to the meadow of milk and honey! 🥛 A soft breeze carries the scent of fresh cream." },
        { who: "milka", text: "Nyaa~! There you are! I'm Milka-chan, your milky guide today!", mood: "celebrate" },
        { who: "milka", text: "I was just waiting for someone to visit my little meadow! The cows are moo-sic today!", mood: "smile" },
      ],
      "ask-name": [
        { who: "milka", text: `Hey hey! Before we start our creamy adventure... what should I call you, traveler?`, mood: "thinking" },
        { who: "milka", text: `I promise I won't moo-nipulate your name! Go on, type it below~ 🐄`, mood: "smile" },
      ],
      "name-input": [],
      greet: [
        { who: "milka", text: `Oh! ${niceName}! What a wonderful name! I'll remember it forever, right next to "favorite snacks"!`, mood: "celebrate" },
        { who: "milka", text: `${niceName}-san, let's do something fun together! I have a little game we can play!`, mood: "happy" },
      ],
      "rhythm-intro": [
        { who: "milka", text: `It's called "Milky Mix!" — a r-rhythm game? You have to tap and slide in time with the milky beat!`, mood: "surprised" },
        { who: "milka", text: `Don't worry, ${niceName}! Even if you miss notes, I'll still share my chocolate milk with you. Probably.`, mood: "wink" as any },
        { who: "milka", text: `Ready? Let's start! 🥛🥁`, mood: "celebrate" },
      ],
      rhythm: [],
      "rhythm-result": [],
      ending: [
        { who: "milka", text: `Wow ${niceName}, that was amazing! Your fingers are like little milk-stir fairies!`, mood: "celebrate" },
        { who: "milka", text: `Thank you for visiting my meadow today! I hope you'll come back soon for more milky adventures! ✨🥛`, mood: "happy" },
        { who: "narrator", text: "[ End of prologue — thank you for playing Milka VN: tasty-Milka web demo! ]" },
      ],
    };
  }, [playerName]);

  const currentScript = script[phase];

  // Typewriter effect when line changes
  useEffect(() => {
    if (!currentScript[currentLine]) return;
    const full = currentScript[currentLine].text;
    setTypewriter("");
    let i = 0;
    if (typingTimer.current) clearInterval(typingTimer.current);
    typingTimer.current = setInterval(() => {
      i++;
      setTypewriter(full.slice(0, i));
      if (i >= full.length) {
        if (typingTimer.current) clearInterval(typingTimer.current);
      }
    }, 22);
    return () => {
      if (typingTimer.current) clearInterval(typingTimer.current);
    };
  }, [currentLine, currentScript]);

  function advanceDialogue() {
    // skip typewriter
    if (typewriter.length < (currentScript[currentLine]?.text.length ?? 0)) {
      if (typingTimer.current) clearInterval(typingTimer.current);
      setTypewriter(currentScript[currentLine].text);
      return;
    }
    const line = currentScript[currentLine];
    if (line?.mood) {
      setMood(line.mood);
      if (line.mood === "celebrate") setAnimClass("anim-bounce");
      else if (line.mood === "surprised") {
        setAnimClass("anim-shake");
        setTimeout(() => setAnimClass("anim-bob"), 500);
      } else if (line.mood === "thinking") {
        setAnimClass("anim-nod");
        setTimeout(() => setAnimClass("anim-bob"), 800);
      } else setAnimClass("anim-bob");
    }
    if (currentLine < currentScript.length - 1) {
      setCurrentLine((c) => c + 1);
    } else {
      // end of script → next phase
      goToNextPhase();
    }
  }

  function goToNextPhase() {
    setCurrentLine(0);
    switch (phase) {
      case "title":
        setPhase("intro");
        setMood("smile");
        break;
      case "intro":
        setPhase("ask-name");
        setMood("thinking");
        break;
      case "ask-name":
        setPhase("name-input");
        setMood("smile");
        break;
      case "name-input":
        // Only advance if name is acceptable
        if (issues.length === 0) {
          setPlayerName(nameValue.trim());
          setPhase("greet");
          setMood("celebrate");
        } else {
          setMood("worried");
        }
        break;
      case "greet":
        setPhase("rhythm-intro");
        setMood("surprised");
        break;
      case "rhythm-intro":
        setPhase("rhythm");
        setMood("happy");
        break;
      case "rhythm":
        setPhase("rhythm-result");
        break;
      case "rhythm-result":
        setPhase("ending");
        setMood("celebrate");
        break;
      case "ending":
        setPhase("title");
        setMood("neutral");
        setPlayerName("traveler");
        setNameValue("");
        setRhythmResult(null);
        break;
    }
  }

  // Live reaction on name input
  useEffect(() => {
    if (phase !== "name-input") return;
    const found = analyzeName(nameValue);
    setIssues(found);
    if (found.length === 0 && nameValue.trim()) {
      setMood("happy");
      setAnimClass("anim-bounce");
    } else if (found.some((x) => x.type === "emoji" || x.type === "math" || x.type === "special")) {
      setMood("surprised");
      setAnimClass("anim-shake");
      setTimeout(() => setAnimClass("anim-bob"), 500);
    } else if (found.some((x) => x.type === "lowercase-start" || x.type === "has-numbers" || x.type === "too-long")) {
      setMood("worried");
      setAnimClass("anim-bob");
    } else if (found.some((x) => x.type === "empty")) {
      setMood("neutral");
      setAnimClass("anim-bob");
    }
  }, [nameValue, phase]);

  // keyboard: space advances dialogue when not in rhythm
  useEffect(() => {
    if (phase === "rhythm" || phase === "name-input" || phase === "title") return;
    const h = (e: KeyboardEvent) => {
      if (e.key === " " || e.key === "Enter") {
        e.preventDefault();
        advanceDialogue();
      }
    };
    window.addEventListener("keydown", h);
    return () => window.removeEventListener("keydown", h);
  });

  // Background per phase
  const bgClass = useMemo(() => {
    switch (phase) {
      case "title":
        return "from-[#ffe4ec] via-[#fff5e6] to-[#e4f0ff]";
      case "ending":
        return "from-[#2b1d36] via-[#4a2f4e] to-[#1a1024]";
      case "rhythm":
      case "rhythm-result":
        return "from-[#1a1024] via-[#2b1d36] to-[#0f0819]";
      default:
        return "from-[#d4f0ff] via-[#fff5e6] to-[#ffe4ec]";
    }
  }, [phase]);

  const onRhythmFinish = (hit: number, total: number, maxCombo: number) => {
    setRhythmResult({ score: hit, total, max: maxCombo });
  };

  // After rhythm is set, we go to result phase
  useEffect(() => {
    if (phase === "rhythm" && rhythmResult) {
      setPhase("rhythm-result");
    }
  }, [rhythmResult, phase]);

  return (
    <main
      className={`relative flex min-h-screen flex-col items-center justify-between bg-gradient-to-b ${bgClass} p-4 transition-colors duration-700`}
    >
      {/* Floating milk droplets decoration */}
      <div className="pointer-events-none absolute inset-0 overflow-hidden">
        {["🥛", "✨", "🍫", "🐄", "💮", "🌸"].map((s, i) => (
          <span
            key={i}
            className="absolute text-2xl opacity-30"
            style={{
              top: `${(i * 17) % 90}%`,
              left: `${(i * 31) % 95}%`,
              animation: `bob ${3 + (i % 3)}s ease-in-out infinite`,
              animationDelay: `${i * 0.3}s`,
            }}
          >
            {s}
          </span>
        ))}
      </div>

      {/* Title screen */}
      {phase === "title" ? (
        <div className="z-10 flex flex-1 flex-col items-center justify-center gap-6 text-center pt-10">
          <div className="text-6xl">🥛</div>
          <h1 className="milka-speech text-5xl md:text-7xl font-bold text-[#8b5a3c] drop-shadow-[3px_3px_0_rgba(255,255,255,0.8)]">
            tasty-Milka
          </h1>
          <p className="text-lg text-[#6b4a2f] milka-speech">a milky visual novel prologue</p>
          <div className="mt-2 flex justify-center anim-bob">
            <MilkaSprite mood="celebrate" />
          </div>
          <button
            onClick={() => {
              setCurrentLine(0);
              setPhase("intro");
              setMood("smile");
            }}
            className="pixel-btn mt-4 rounded-2xl bg-[#ff9fb3] px-10 py-4 text-2xl font-bold text-white shadow-xl anim-pulse-glow"
          >
            ▶ Start
          </button>
          <p className="text-sm text-[#6b4a2f]/70 mt-2">click through dialogue · space / enter to advance</p>
        </div>
      ) : (
        <>
          {/* Stage area */}
          <div className="z-10 flex w-full flex-1 flex-col items-center justify-end pb-4 pt-6">
            {phase !== "rhythm" && phase !== "rhythm-result" && (
              <div className={animClass}>
                <MilkaSprite mood={mood} />
              </div>
            )}
            {phase === "rhythm" && (
              <div className="flex flex-col items-center w-full">
                <RhythmGame
                  onFinish={(s, t, m) => onRhythmFinish(s, t, m)}
                />
              </div>
            )}
            {phase === "rhythm-result" && rhythmResult && (
              <div className="flex flex-col items-center gap-4 rounded-2xl bg-white/95 p-8 shadow-2xl border-4 border-[#c9a27a] max-w-lg w-full">
                <div className="text-4xl">🥛🎶</div>
                <h2 className="milka-speech text-3xl font-bold text-[#8b5a3c]">Song complete!</h2>
                <div className="text-center text-lg">
                  <div>Notes hit: <b>{rhythmResult.score}</b> / {rhythmResult.total}</div>
                  <div>Max combo: <b>{rhythmResult.max}x</b></div>
                  <div className="mt-2 text-xl font-bold text-[#d08b0e]">
                    {rhythmResult.score === rhythmResult.total
                      ? "PERFECT RUN! Milka is giving you a gold milk sticker! 🥇"
                      : rhythmResult.score >= rhythmResult.total * 0.7
                      ? "Great job! You get extra chocolate milk! 🍫🥛"
                      : rhythmResult.score >= rhythmResult.total * 0.4
                      ? "Nice try! Practice makes purr-fect~ 🐾"
                      : "It's okay! I'll still share my milk with you. 💛"}
                  </div>
                </div>
                <button
                  className="pixel-btn rounded-xl bg-[#ff9fb3] px-6 py-3 text-lg font-bold text-white shadow-lg"
                  onClick={() => {
                    setCurrentLine(0);
                    setPhase("ending");
                    setMood("celebrate");
                  }}
                >
                  Continue ▸
                </button>
              </div>
            )}
          </div>

          {/* Name input phase */}
          {phase === "name-input" ? (
            <div className="z-10 w-full max-w-3xl flex flex-col items-center gap-3">
              {/* Live reaction dialogue */}
              <div className="w-full">
                <div className="rounded-2xl border-4 border-[#c9a27a] bg-white/95 px-6 py-4 shadow-2xl milka-speech min-h-[7rem]">
                  <div className="mb-1 text-xs font-bold uppercase tracking-widest text-[#8b5a3c]/70">Milka-chan</div>
                  {nameValue.trim() === "" ? (
                    <p className="text-lg leading-relaxed">
                      Go on, type your name! I&apos;m listening with my little cow ears~ 🐄
                    </p>
                  ) : issues.length === 0 ? (
                    <p className="text-lg leading-relaxed">
                      Oh! <b className="text-[#d08b0e]">{nameValue.trim()}</b>! That&apos;s such a lovely name! It sounds so sparkly~ ✨
                      <br />
                      <span className="text-sm text-[#6b4a2f]/80">(Press confirm to continue!)</span>
                    </p>
                  ) : (
                    <div className="space-y-1 text-lg leading-relaxed">
                      <p>Eeeeh? Wait a second, <b className="text-[#c04a4a]">{nameValue}</b>... </p>
                      <ul className="list-disc pl-6 text-base">
                        {issues.map((iss, i) => (
                          <li key={i}>
                            {iss.type === "lowercase-start" && "it doesn't start with a capital letter! Are you feeling lowercase today?"}
                            {iss.type === "has-numbers" && "it has numbers in it! Are you a secret agent, like Subject-07?!"}
                            {iss.type === "emoji" && "there's an emoji in there! I can't pronounce sparkles with my mouth full of milk!"}
                            {iss.type === "math" && "that's math! I failed hay arithmetic in cow school!"}
                            {iss.type === "special" && "weird symbols detected! Is that a spell to turn me into chocolate milk?!"}
                            {iss.type === "too-long" && "that's way too long! I have the memory of a goldfish-cow!"}
                          </li>
                        ))}
                      </ul>
                      <p className="text-sm text-[#6b4a2f]/80">Fix it up and we can be friends forever~ 🥛</p>
                    </div>
                  )}
                </div>
              </div>
              <div className="flex w-full items-center gap-3 rounded-2xl bg-white/90 p-3 shadow-xl border-2 border-[#c9a27a]">
                <input
                  type="text"
                  autoFocus
                  value={nameValue}
                  onChange={(e) => setNameValue(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === "Enter" && issues.length === 0 && nameValue.trim()) {
                      goToNextPhase();
                    }
                  }}
                  placeholder="Enter your name..."
                  maxLength={24}
                  className="flex-1 rounded-xl border-2 border-[#e0c9a7] bg-[#fff8ef] px-4 py-3 text-lg outline-none focus:border-[#ff9fb3] milka-speech"
                />
                <button
                  onClick={() => {
                    if (issues.length === 0 && nameValue.trim()) {
                      goToNextPhase();
                    }
                  }}
                  disabled={issues.length > 0 || !nameValue.trim()}
                  className="pixel-btn rounded-xl bg-[#ff9fb3] px-5 py-3 text-lg font-bold text-white shadow-md"
                >
                  Confirm 💮
                </button>
              </div>
            </div>
          ) : phase === "rhythm" || phase === "rhythm-result" ? null : (
            /* Dialogue box for talk phases */
            currentScript[currentLine] && (
              <div className="z-10 w-full max-w-3xl" onClick={advanceDialogue}>
                <DialogueBox
                  line={{ ...currentScript[currentLine], text: typewriter || currentScript[currentLine].text }}
                  onAdvance={advanceDialogue}
                />
              </div>
            )
          )}
        </>
      )}

      {/* Footer */}
      <div className="z-10 mt-4 text-center text-xs text-[#6b4a2f]/60">
        tasty-Milka web demo · branch feature/putin-milka-name-rhythm-VPALPHA7
      </div>
    </main>
  );
}
