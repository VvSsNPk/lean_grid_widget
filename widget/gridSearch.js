// Grid search visualiser for the Lean infoview.
// Props (see `GridSearch.GridSearchProps`): { grid, algo, result }.
// Edits to the grid are sent back to Lean via the `GridSearch.runSearch` RPC method.
import * as React from 'react';
import { useRpcSession } from '@leanprover/infoview';

const e = React.createElement;

const ALGOS = [
  ['bfs', 'Breadth-first'],
  ['dfs', 'Depth-first'],
  ['greedy', 'Greedy best-first'],
  ['astar', 'A*'],
];

const COLORS = {
  empty: 'var(--vscode-editor-background, #fff)',
  wall: '#3b3b3b',
  closed: '#9ec5fe',
  frontier: '#ffd479',
  current: '#ff8c1a',
  path: '#5cc97b',
  start: '#1f9d55',
  goal: '#d64545',
  border: 'var(--vscode-editorWidget-border, #c8c8c8)',
};

function cellState(i, k, grid, result, onPath) {
  if (grid.walls[i]) return 'wall';
  if (i === grid.start) return 'start';
  if (i === grid.goal) return 'goal';
  if (onPath.has(i)) return 'path';
  const c = result.closedAt[i], o = result.openedAt[i];
  if (c >= 0 && c === k) return 'current';
  if (c >= 0 && c < k) return 'closed';
  if (o >= 0 && o <= k) return 'frontier';
  return 'empty';
}

function Button(props) {
  const { active, ...rest } = props;
  return e('button', {
    ...rest,
    style: {
      padding: '2px 8px',
      cursor: 'pointer',
      border: `1px solid ${COLORS.border}`,
      borderRadius: 3,
      background: active ? 'var(--vscode-button-background, #0e639c)' : 'transparent',
      color: active ? 'var(--vscode-button-foreground, #fff)' : 'inherit',
      font: 'inherit',
    },
  });
}

function Legend() {
  const items = [
    ['start', 'start'], ['goal', 'goal'], ['wall', 'wall'], ['frontier', 'frontier'],
    ['current', 'expanding'], ['closed', 'expanded'], ['path', 'path'],
  ];
  return e('div', { style: { display: 'flex', flexWrap: 'wrap', gap: 10, fontSize: '0.85em' } },
    items.map(([k, label]) => e('span', { key: k, style: { display: 'inline-flex', alignItems: 'center', gap: 4 } },
      e('span', { style: { width: 12, height: 12, background: COLORS[k], border: `1px solid ${COLORS.border}`, display: 'inline-block' } }),
      label)));
}

export default function GridSearchViz(props) {
  const rs = useRpcSession();
  const [grid, setGrid] = React.useState(props.grid);
  const [algo, setAlgo] = React.useState(props.algo);
  const [result, setResult] = React.useState(props.result);
  const [step, setStep] = React.useState(0);
  const [playing, setPlaying] = React.useState(false);
  const [speed, setSpeed] = React.useState(60);
  const [mode, setMode] = React.useState('wall');
  const [error, setError] = React.useState(null);
  const paint = React.useRef(null);   // wall value being painted while dragging, or null
  const firstRun = React.useRef(true);

  const maxStep = result.steps;       // frames 0..steps-1 are expansions, `steps` is the final frame

  // Rerun the search in Lean whenever the grid or algorithm changes.
  React.useEffect(() => {
    if (firstRun.current) { firstRun.current = false; return; }
    let cancelled = false;
    setPlaying(false);
    rs.call('GridSearch.runSearch', { grid, algo })
      .then(r => { if (!cancelled) { setResult(r); setStep(r.steps); setError(null); } })
      .catch(err => { if (!cancelled) setError(String(err?.message ?? err)); });
    return () => { cancelled = true; };
  }, [grid, algo]);

  React.useEffect(() => {
    if (!playing) return;
    if (step >= maxStep) { setPlaying(false); return; }
    const t = setTimeout(() => setStep(s => Math.min(s + 1, maxStep)), speed);
    return () => clearTimeout(t);
  }, [playing, step, maxStep, speed]);

  React.useEffect(() => {
    const up = () => { paint.current = null; };
    window.addEventListener('mouseup', up);
    return () => window.removeEventListener('mouseup', up);
  }, []);

  const onPath = React.useMemo(
    () => new Set(step >= maxStep && result.found ? result.path : []),
    [step, maxStep, result]);

  const setWall = (i, v) => {
    if (i === grid.start || i === grid.goal || grid.walls[i] === v) return;
    setGrid(g => { const walls = g.walls.slice(); walls[i] = v; return { ...g, walls }; });
  };

  const onDown = i => {
    if (mode === 'wall') { paint.current = !grid.walls[i]; setWall(i, paint.current); }
    else if (!grid.walls[i] && i !== grid.start && i !== grid.goal)
      setGrid(g => ({ ...g, [mode]: i }));
  };
  const onEnter = i => { if (paint.current !== null) setWall(i, paint.current); };

  const cell = Math.max(10, Math.min(28, Math.floor(560 / grid.width)));
  const cells = [];
  for (let i = 0; i < grid.width * grid.height; i++) {
    const st = cellState(i, step, grid, result, onPath);
    cells.push(e('div', {
      key: i,
      onMouseDown: ev => { ev.preventDefault(); onDown(i); },
      onMouseEnter: () => onEnter(i),
      title: `(${Math.floor(i / grid.width)}, ${i % grid.width})`,
      style: {
        width: cell, height: cell, boxSizing: 'border-box',
        background: COLORS[st],
        border: `1px solid ${COLORS.border}`,
        transition: 'background 80ms',
        cursor: 'pointer',
      },
    }));
  }

  const k = Math.min(step, maxStep);
  const expanded = result.closedAt.filter(c => c >= 0 && c <= k).length;
  const frontier = result.openedAt.filter((o, i) => o >= 0 && o <= k && !(result.closedAt[i] >= 0 && result.closedAt[i] <= k)).length;

  const togglePlay = () => {
    if (playing) { setPlaying(false); return; }
    if (step >= maxStep) setStep(0);
    setPlaying(true);
  };

  return e('div', { style: { display: 'flex', flexDirection: 'column', gap: 8, userSelect: 'none' } },
    // Algorithm + edit mode
    e('div', { style: { display: 'flex', flexWrap: 'wrap', gap: 6, alignItems: 'center' } },
      e('select', { value: algo, onChange: ev => setAlgo(ev.target.value), style: { font: 'inherit' } },
        ALGOS.map(([v, l]) => e('option', { key: v, value: v }, l))),
      e('span', { style: { marginLeft: 8 } }, 'Edit:'),
      ['wall', 'start', 'goal'].map(m => e(Button, { key: m, active: mode === m, onClick: () => setMode(m) }, m)),
      e(Button, { onClick: () => setGrid(g => ({ ...g, walls: g.walls.map(() => false) })) }, 'clear walls'),
      e(Button, { onClick: () => setGrid(props.grid) }, 'reset')),
    // Grid
    e('div', {
      style: {
        display: 'grid',
        gridTemplateColumns: `repeat(${grid.width}, ${cell}px)`,
        width: 'max-content',
      },
      onMouseLeave: () => { paint.current = null; },
    }, cells),
    // Playback
    e('div', { style: { display: 'flex', flexWrap: 'wrap', gap: 6, alignItems: 'center' } },
      e(Button, { onClick: () => { setPlaying(false); setStep(0); } }, '⏮'),
      e(Button, { onClick: () => { setPlaying(false); setStep(s => Math.max(0, s - 1)); } }, '◀'),
      e(Button, { onClick: togglePlay, active: playing }, playing ? '⏸' : '▶'),
      e(Button, { onClick: () => { setPlaying(false); setStep(s => Math.min(maxStep, s + 1)); } }, '▶|'),
      e(Button, { onClick: () => { setPlaying(false); setStep(maxStep); } }, '⏭'),
      e('input', {
        type: 'range', min: 0, max: maxStep, value: k, style: { flex: '1 1 150px' },
        onChange: ev => { setPlaying(false); setStep(Number(ev.target.value)); },
      }),
      e('select', { value: speed, onChange: ev => setSpeed(Number(ev.target.value)), style: { font: 'inherit' } },
        [[250, 'slow'], [60, 'normal'], [15, 'fast']].map(([v, l]) => e('option', { key: v, value: v }, l)))),
    // Stats
    e('div', { style: { fontSize: '0.9em' } },
      `step ${k} / ${maxStep} · expanded ${expanded} · frontier ${frontier} · `,
      k >= maxStep
        ? (result.found ? `path length ${result.path.length - 1}` : 'goal unreachable')
        : 'searching…'),
    error && e('div', { style: { color: 'var(--vscode-errorForeground, red)' } }, error),
    e(Legend));
}
