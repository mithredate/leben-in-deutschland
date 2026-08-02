import { store } from './store.js';
import { gradeAnswer, queueFor, buildSession, summarize, dueCount, dailyTarget } from './srs.js';

const STATES = {
  BW: 'Baden-Württemberg', BY: 'Bayern', BE: 'Berlin', BB: 'Brandenburg',
  HB: 'Bremen', HH: 'Hamburg', HE: 'Hessen', MV: 'Mecklenburg-Vorpommern',
  NI: 'Niedersachsen', NW: 'Nordrhein-Westfalen', RP: 'Rheinland-Pfalz',
  SL: 'Saarland', SN: 'Sachsen', ST: 'Sachsen-Anhalt',
  SH: 'Schleswig-Holstein', TH: 'Thüringen',
};

const PASS = { lid: 15, einbuergerung: 17 };
const EXAM_MINUTES = 60;

let QUESTIONS = [];
let activeTab = 'home';

const $view = document.getElementById('view');
const $overlay = document.getElementById('overlay');
const $tabbar = document.getElementById('tabbar');

const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({
  '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
}[c]));

// ---------------------------------------------------------------- data

function pool() {
  const st = store.settings.state;
  return QUESTIONS.filter((q) => !q.state || q.state === st);
}

function generalQuestions() {
  return QUESTIONS.filter((q) => !q.state);
}

function stateQuestions() {
  const st = store.settings.state;
  return QUESTIONS.filter((q) => q.state === st);
}

// answers stay in catalog order when they point at image positions or are bare numbers
function isPositional(q) {
  return q.answers.every((a) => /^(bild\s*)?\d+\s*€?$/i.test(a.trim()));
}

function shuffled(arr) {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

// ---------------------------------------------------------------- tabs

$tabbar.addEventListener('click', (e) => {
  const btn = e.target.closest('[data-tab]');
  if (!btn) return;
  activeTab = btn.dataset.tab;
  for (const t of $tabbar.querySelectorAll('.tab')) t.classList.toggle('active', t === btn);
  render();
});

function render() {
  ({ home: renderHome, browse: renderBrowse, exam: renderExamEntry, more: renderMore })[activeTab]();
  $view.scrollTop = 0;
  window.scrollTo(0, 0);
}

// ---------------------------------------------------------------- home

function flagBar(s) {
  const pct = (n) => (100 * n / s.total).toFixed(2) + '%';
  return `
  <div class="flagbar" role="img" aria-label="${s.mastered} gemeistert, ${s.learning} in Arbeit, ${s.new} neu">
    <div class="band band-gold" style="width:${pct(s.mastered)}"></div>
    <div class="band band-red" style="width:${pct(s.learning)}"></div>
    <div class="band band-black" style="width:${pct(s.new)}"></div>
  </div>
  <div class="flaglegend">
    <span><i class="dot dot-gold"></i>${s.mastered} sicher</span>
    <span><i class="dot dot-red"></i>${s.learning} in Arbeit</span>
    <span><i class="dot dot-black"></i>${s.new} neu</span>
  </div>`;
}

function renderHome() {
  const settings = store.settings;
  const progress = store.progress;
  const all = pool();
  const s = summarize(all, progress);
  const due = dueCount(all, progress);
  const { perDay, daysLeft } = dailyTarget(s, settings.examDate);
  const today = store.answeredToday();
  const streak = store.streak();
  const lastExam = store.exams.at(-1);

  $view.innerHTML = `
  <header class="head">
    <p class="eyebrow">Leben in Deutschland</p>
    <h1>Testtrainer</h1>
  </header>

  <section class="card countdown">
    <div class="count-num">${daysLeft}</div>
    <div class="count-label">Tag${daysLeft === 1 ? '' : 'e'} bis zur Prüfung<br>
      <small>${new Date(settings.examDate).toLocaleDateString('de-DE', { weekday: 'long', day: 'numeric', month: 'long' })}
      · ${esc(STATES[settings.state] || '')}</small></div>
  </section>

  <section class="card">
    <h2>Dein Fortschritt</h2>
    ${flagBar(s)}
    <div class="statgrid">
      <div><b>${due}</b><span>fällig</span></div>
      <div><b>${today}</b><span>heute geübt</span></div>
      <div><b>${streak}</b><span>Tage-Serie</span></div>
      <div><b>${Math.max(0, perDay)}</b><span>neue/Tag nötig</span></div>
    </div>
  </section>

  <button class="btn btn-primary btn-big" id="btn-study">
    ${due > 0 ? `Wiederholen &amp; Lernen (${Math.min(20, due + s.new)})` : s.new > 0 ? 'Neue Fragen lernen' : 'Alles gemeistert – Fehler wiederholen'}
  </button>
  <button class="btn btn-ghost" id="btn-exam">Testsimulation starten</button>

  ${lastExam ? `<p class="lastexam">Letzte Simulation: <b>${lastExam.score}/33</b> ${lastExam.score >= PASS.lid ? '✓ bestanden' : '✗ nicht bestanden'}</p>` : ''}
  `;

  document.getElementById('btn-study').onclick = () => startStudy();
  document.getElementById('btn-exam').onclick = () => startExam();
}

// ---------------------------------------------------------------- quiz card (shared)

// Renders one question into `container`. opts: {mode:'study'|'exam', picked, onAnswer, lang}
function questionCard(container, q, opts = {}) {
  const lang = opts.lang || store.settings.lang;
  const order = isPositional(q) ? [0, 1, 2, 3] : shuffled([0, 1, 2, 3]);
  const en = q.en || {};

  container.innerHTML = `
  <article class="qcard">
    <p class="qnum">Frage ${esc(q.num)} · ${esc(q.category)}</p>
    <h2 class="qtext">${esc(q.question)}</h2>
    ${lang === 'en' && en.question ? `<p class="qtrans">${esc(en.question)}</p>` : ''}
    ${q.image ? `<img class="qimg" src="img/${esc(q.image)}" alt="Abbildung zu Frage ${esc(q.num)}" loading="lazy">` : ''}
    <div class="answers">
      ${order.map((i, pos) => `
        <button class="answer" data-i="${i}">
          <span class="answer-letter">${'ABCD'[pos]}</span>
          <span>${esc(q.answers[i])}</span>
        </button>`).join('')}
    </div>
    <div class="feedback hidden"></div>
  </article>`;

  const $answers = container.querySelectorAll('.answer');
  const $feedback = container.querySelector('.feedback');

  for (const btn of $answers) {
    btn.onclick = () => {
      const i = Number(btn.dataset.i);
      const correct = i === q.correct;
      for (const b of $answers) {
        b.disabled = true;
        const bi = Number(b.dataset.i);
        if (bi === q.correct) b.classList.add('is-correct');
        else if (b === btn) b.classList.add('is-wrong');
      }
      if (!correct) btn.classList.add('shake');

      const expl = lang === 'en' ? (q.en && q.en.explanation) : q.explanation_de;
      const altExpl = lang === 'en' ? q.explanation_de : (q.en && q.en.explanation);
      $feedback.classList.remove('hidden');
      $feedback.innerHTML = `
        <p class="verdict ${correct ? 'ok' : 'bad'}">${correct ? 'Richtig!' : 'Leider falsch.'}</p>
        ${expl ? `<details class="expl" ${correct ? '' : 'open'}><summary>Erklärung</summary><p>${esc(expl)}</p>
          ${altExpl ? `<button class="linkbtn" data-alt>Auf ${lang === 'en' ? 'Deutsch' : 'Englisch'} zeigen</button><p class="hidden" data-altp>${esc(altExpl)}</p>` : ''}
        </details>` : ''}`;
      const altBtn = $feedback.querySelector('[data-alt]');
      if (altBtn) altBtn.onclick = () => {
        $feedback.querySelector('[data-altp]').classList.toggle('hidden');
      };
      opts.onAnswer && opts.onAnswer(correct, i);
    };
  }
}

// ---------------------------------------------------------------- study session

function startStudy(list) {
  const progress = store.progress;
  const session = list || buildSession(pool(), progress, 20);
  if (!session.length) {
    toast('Nichts fällig – alles gelernt! 🎉');
    return;
  }
  let idx = 0;
  let right = 0;

  openOverlay(`
    <div class="ov-head">
      <button class="ov-close" data-close>✕</button>
      <div class="ov-progress"><div class="ov-progress-fill" style="width:0%"></div></div>
      <span class="ov-count"></span>
    </div>
    <div class="ov-body"></div>
    <div class="ov-foot hidden"><button class="btn btn-primary btn-big" data-next>Weiter</button></div>
  `);

  const $body = $overlay.querySelector('.ov-body');
  const $foot = $overlay.querySelector('.ov-foot');
  const $fill = $overlay.querySelector('.ov-progress-fill');
  const $count = $overlay.querySelector('.ov-count');

  function show() {
    if (idx >= session.length) return finish();
    $fill.style.width = `${(100 * idx) / session.length}%`;
    $count.textContent = `${idx + 1}/${session.length}`;
    $foot.classList.add('hidden');
    questionCard($body, session[idx], {
      mode: 'study',
      onAnswer(correct) {
        const p = store.progress;
        p[session[idx].id] = gradeAnswer(p[session[idx].id], correct);
        store.progress = p;
        store.recordAnswer(session[idx].id, correct);
        if (correct) right += 1;
        $foot.classList.remove('hidden');
      },
    });
    $body.scrollTop = 0;
  }

  function finish() {
    $body.innerHTML = `
      <div class="finish">
        <div class="finish-num">${right}/${session.length}</div>
        <p>${right === session.length ? 'Perfekte Runde!' : right >= session.length * 0.7 ? 'Gut gemacht – weiter so.' : 'Die Fehler kommen gleich wieder dran.'}</p>
        <button class="btn btn-primary btn-big" data-again>Nächste Runde</button>
        <button class="btn btn-ghost" data-close>Fertig für jetzt</button>
      </div>`;
    $foot.classList.add('hidden');
    $fill.style.width = '100%';
    $body.querySelector('[data-again]').onclick = () => { closeOverlay(); startStudy(); };
  }

  $overlay.querySelector('[data-next]').onclick = () => { idx += 1; show(); };
  show();
}

// ---------------------------------------------------------------- exam

function renderExamEntry() {
  const exams = store.exams;
  $view.innerHTML = `
  <header class="head">
    <p class="eyebrow">Simulation</p>
    <h1>Testsimulation</h1>
  </header>
  <section class="card">
    <p>Wie in der echten Prüfung: <b>33 Fragen</b> (30 allgemeine + 3 aus ${esc(STATES[store.settings.state] || 'deinem Bundesland')}), <b>60 Minuten</b> Zeit.</p>
    <ul class="rules">
      <li>„Leben in Deutschland“ (Niederlassungserlaubnis): <b>ab 15 richtigen</b> bestanden</li>
      <li>Einbürgerungstest: <b>ab 17 richtigen</b> bestanden</li>
    </ul>
    <button class="btn btn-primary btn-big" id="btn-start-exam">Simulation starten</button>
  </section>
  ${exams.length ? `
  <section class="card">
    <h2>Bisherige Simulationen</h2>
    <ul class="examlist">
      ${exams.slice(-10).reverse().map((e) => `
        <li><span>${new Date(e.date).toLocaleDateString('de-DE', { day: '2-digit', month: '2-digit' })}
        ${new Date(e.date).toLocaleTimeString('de-DE', { hour: '2-digit', minute: '2-digit' })}</span>
        <b class="${e.score >= PASS.lid ? 'ok' : 'bad'}">${e.score}/33</b></li>`).join('')}
    </ul>
  </section>` : ''}`;
  document.getElementById('btn-start-exam').onclick = () => startExam();
}

function startExam() {
  const st = stateQuestions();
  if (!st.length) { showOnboarding(); return; }
  const qs = shuffled([
    ...shuffled(generalQuestions()).slice(0, 30),
    ...shuffled(st).slice(0, 3),
  ]);
  const picked = new Array(qs.length).fill(null);
  let idx = 0;
  const deadline = Date.now() + EXAM_MINUTES * 60 * 1000;
  let timerId;

  openOverlay(`
    <div class="ov-head exam-head">
      <button class="ov-close" data-close>✕</button>
      <span class="exam-timer" id="exam-timer">60:00</span>
      <button class="btn btn-small btn-gold" data-submit>Abgeben</button>
    </div>
    <div class="exam-dots" id="exam-dots"></div>
    <div class="ov-body"></div>
    <div class="ov-foot exam-foot">
      <button class="btn btn-ghost" data-prev>← Zurück</button>
      <button class="btn btn-primary" data-nextq>Weiter →</button>
    </div>
  `, { onClose: () => clearInterval(timerId) });

  const $body = $overlay.querySelector('.ov-body');
  const $dots = document.getElementById('exam-dots');
  const $timer = document.getElementById('exam-timer');

  function tick() {
    const left = Math.max(0, deadline - Date.now());
    const m = Math.floor(left / 60000);
    const s = Math.floor((left % 60000) / 1000);
    $timer.textContent = `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
    $timer.classList.toggle('urgent', left < 5 * 60000);
    if (left <= 0) { clearInterval(timerId); submit(); }
  }
  timerId = setInterval(tick, 1000);

  function drawDots() {
    $dots.innerHTML = qs.map((_, i) =>
      `<button class="dot-q ${picked[i] != null ? 'done' : ''} ${i === idx ? 'cur' : ''}" data-goto="${i}">${i + 1}</button>`
    ).join('');
    for (const b of $dots.querySelectorAll('[data-goto]')) {
      b.onclick = () => { idx = Number(b.dataset.goto); show(); };
    }
    const cur = $dots.querySelector('.cur');
    if (cur) cur.scrollIntoView({ block: 'nearest', inline: 'center' });
  }

  function show() {
    const q = qs[idx];
    const order = isPositional(q) ? [0, 1, 2, 3] : q._order || (q._order = shuffled([0, 1, 2, 3]));
    $body.innerHTML = `
      <article class="qcard">
        <p class="qnum">Aufgabe ${idx + 1} von ${qs.length}${q.state ? ' · Bundesland' : ''}</p>
        <h2 class="qtext">${esc(q.question)}</h2>
        ${q.image ? `<img class="qimg" src="img/${esc(q.image)}" alt="Abbildung" loading="lazy">` : ''}
        <div class="answers">
          ${order.map((i, pos) => `
            <button class="answer ${picked[idx] === i ? 'is-picked' : ''}" data-i="${i}">
              <span class="answer-letter">${'ABCD'[pos]}</span><span>${esc(q.answers[i])}</span>
            </button>`).join('')}
        </div>
      </article>`;
    for (const b of $body.querySelectorAll('.answer')) {
      b.onclick = () => {
        picked[idx] = Number(b.dataset.i);
        if (idx < qs.length - 1) { idx += 1; show(); }
        else { drawDots(); show(); }
      };
    }
    drawDots();
    $body.scrollTop = 0;
  }

  $overlay.querySelector('[data-prev]').onclick = () => { if (idx > 0) { idx -= 1; show(); } };
  $overlay.querySelector('[data-nextq]').onclick = () => { if (idx < qs.length - 1) { idx += 1; show(); } };
  $overlay.querySelector('[data-submit]').onclick = () => {
    const open = picked.filter((p) => p == null).length;
    if (open && !confirm(`${open} Frage${open === 1 ? '' : 'n'} unbeantwortet. Trotzdem abgeben?`)) return;
    submit();
  };

  function submit() {
    clearInterval(timerId);
    let score = 0;
    const wrong = [];
    const p = store.progress;
    qs.forEach((q, i) => {
      const correct = picked[i] === q.correct;
      if (correct) score += 1;
      else wrong.push({ q, picked: picked[i] });
      p[q.id] = gradeAnswer(p[q.id], correct);
      store.recordAnswer(q.id, correct);
      delete q._order;
    });
    store.progress = p;
    store.exams = [...store.exams, {
      date: new Date().toISOString(), score, total: qs.length,
      passedLid: score >= PASS.lid, passedEinb: score >= PASS.einbuergerung,
    }];

    $overlay.querySelector('.ov-head').remove();
    $dots.remove();
    $overlay.querySelector('.ov-foot').remove();
    $body.innerHTML = `
      <div class="finish">
        <p class="eyebrow">Ergebnis</p>
        <div class="finish-num ${score >= PASS.lid ? 'ok' : 'bad'}">${score}/33</div>
        <div class="passgrid">
          <div class="${score >= PASS.lid ? 'pass' : 'fail'}">Leben in Deutschland (NE)<br><b>${score >= PASS.lid ? 'bestanden ✓' : 'nicht bestanden ✗'}</b></div>
          <div class="${score >= PASS.einbuergerung ? 'pass' : 'fail'}">Einbürgerung<br><b>${score >= PASS.einbuergerung ? 'bestanden ✓' : 'nicht bestanden ✗'}</b></div>
        </div>
        ${wrong.length ? `<h3 class="wrong-h">Falsche Antworten (${wrong.length})</h3>
        <div class="wronglist">
          ${wrong.map(({ q, picked: pk }) => `
            <div class="wrongitem">
              <p class="qnum">Frage ${esc(q.num)}</p>
              <p class="wq">${esc(q.question)}</p>
              ${q.image ? `<img class="qimg qimg-small" src="img/${esc(q.image)}" alt="" loading="lazy">` : ''}
              <p class="wa bad">Deine Antwort: ${pk != null ? esc(q.answers[pk]) : '–'}</p>
              <p class="wa ok">Richtig: ${esc(q.answers[q.correct])}</p>
              ${q.en && q.en.explanation ? `<details class="expl"><summary>Erklärung</summary><p>${esc(store.settings.lang === 'en' ? q.en.explanation : (q.explanation_de || q.en.explanation))}</p></details>` : ''}
            </div>`).join('')}
        </div>
        <button class="btn btn-primary btn-big" data-drill>Fehler jetzt üben (${wrong.length})</button>` : ''}
        <button class="btn btn-ghost" data-close>Schließen</button>
      </div>`;
    const drill = $body.querySelector('[data-drill]');
    if (drill) drill.onclick = () => { closeOverlay(); startStudy(wrong.map((w) => w.q)); };
    if (activeTab === 'exam' || activeTab === 'home') render();
  }

  show();
  tick();
}

// ---------------------------------------------------------------- browse

let browseFilter = { text: '', cat: 'alle', status: 'alle' };

function renderBrowse() {
  const progress = store.progress;
  const all = pool();
  const cats = [...new Set(all.map((q) => q.category))];

  const rows = all.filter((q) => {
    if (browseFilter.cat !== 'alle' && q.category !== browseFilter.cat) return false;
    const e = progress[q.id];
    if (browseFilter.status === 'neu' && e && e.seen > 0) return false;
    if (browseFilter.status === 'fehler' && (!e || e.box !== 1)) return false;
    if (browseFilter.status === 'sicher' && (!e || e.box < 5)) return false;
    if (browseFilter.text) {
      const t = browseFilter.text.toLowerCase();
      if (!q.question.toLowerCase().includes(t) && !q.num.toLowerCase().includes(t)
        && !q.answers.some((a) => a.toLowerCase().includes(t))) return false;
    }
    return true;
  });

  $view.innerHTML = `
  <header class="head">
    <p class="eyebrow">${all.length} Fragen im Katalog</p>
    <h1>Fragen</h1>
  </header>
  <div class="filters">
    <input type="search" id="f-text" placeholder="Suchen…" value="${esc(browseFilter.text)}">
    <div class="filterrow">
      <select id="f-cat">
        <option value="alle">Alle Themen</option>
        ${cats.map((c) => `<option ${browseFilter.cat === c ? 'selected' : ''}>${esc(c)}</option>`).join('')}
      </select>
      <select id="f-status">
        <option value="alle">Jeder Status</option>
        <option value="neu" ${browseFilter.status === 'neu' ? 'selected' : ''}>Neu</option>
        <option value="fehler" ${browseFilter.status === 'fehler' ? 'selected' : ''}>Fehler</option>
        <option value="sicher" ${browseFilter.status === 'sicher' ? 'selected' : ''}>Sicher</option>
      </select>
    </div>
  </div>
  <p class="resultcount">${rows.length} Treffer ${rows.length ? `· <button class="linkbtn" id="f-practice">diese üben</button>` : ''}</p>
  <ul class="qlist">
    ${rows.map((q) => {
      const e = progress[q.id];
      const cls = !e || e.seen === 0 ? 'st-new' : e.box >= 5 ? 'st-done' : e.box === 1 ? 'st-wrong' : 'st-learn';
      return `<li class="qrow" data-id="${q.id}">
        <span class="qrow-dot ${cls}"></span>
        <span class="qrow-num">${esc(q.num)}</span>
        <span class="qrow-text">${esc(q.question)}</span>
      </li>`;
    }).join('')}
  </ul>`;

  document.getElementById('f-text').oninput = (e) => { browseFilter.text = e.target.value; renderBrowse(); };
  document.getElementById('f-cat').onchange = (e) => { browseFilter.cat = e.target.value; renderBrowse(); };
  document.getElementById('f-status').onchange = (e) => { browseFilter.status = e.target.value; renderBrowse(); };
  const practiceBtn = document.getElementById('f-practice');
  if (practiceBtn) practiceBtn.onclick = () => startStudy(shuffled(rows).slice(0, 30));
  for (const row of $view.querySelectorAll('.qrow')) {
    row.onclick = () => {
      const q = QUESTIONS.find((x) => x.id === row.dataset.id);
      startStudy([q]);
    };
  }
  const search = document.getElementById('f-text');
  search.setSelectionRange(search.value.length, search.value.length);
}

// ---------------------------------------------------------------- more (settings + knowledge)

function renderMore() {
  const settings = store.settings;
  $view.innerHTML = `
  <header class="head">
    <p class="eyebrow">Einstellungen &amp; Wissen</p>
    <h1>Mehr</h1>
  </header>

  <section class="card">
    <h2>Einstellungen</h2>
    <label class="field">Bundesland
      <select id="s-state">
        ${Object.entries(STATES).map(([k, v]) => `<option value="${k}" ${settings.state === k ? 'selected' : ''}>${v}</option>`).join('')}
      </select>
    </label>
    <label class="field">Erklärungen
      <select id="s-lang">
        <option value="en" ${settings.lang === 'en' ? 'selected' : ''}>Englisch</option>
        <option value="de" ${settings.lang === 'de' ? 'selected' : ''}>Deutsch</option>
      </select>
    </label>
    <label class="field">Prüfungsdatum
      <input type="date" id="s-date" value="${esc(settings.examDate)}">
    </label>
  </section>

  <section class="card">
    <h2>So läuft die Prüfung</h2>
    <ul class="info">
      <li><b>33 Fragen</b>, Mehrfachauswahl, genau eine Antwort richtig.</li>
      <li><b>60 Minuten</b> Zeit – die meisten sind nach 15–20 Minuten fertig.</li>
      <li>30 Fragen aus dem Katalog (300) + 3 aus deinem Bundesland (10).</li>
      <li>Für die <b>Niederlassungserlaubnis</b> („Leben in Deutschland“): <b>15 richtige</b> reichen.</li>
      <li>Für die <b>Einbürgerung</b> zählt dieselbe Prüfung ab <b>17 richtigen</b> – schaffst du 17+, ist das Zertifikat später auch dafür gültig.</li>
      <li>Mitbringen: <b>Ausweis/Pass</b> und die Einladung. Handy bleibt aus.</li>
      <li>Es gibt keine Minuspunkte – <b>nie eine Frage offen lassen</b>, im Zweifel raten.</li>
    </ul>
  </section>

  <section class="card">
    <h2>Merkhilfen – die Zahlen, die immer drankommen</h2>
    <ul class="info">
      <li><b>1949</b> Grundgesetz · <b>1961</b> Mauerbau · <b>9. Nov 1989</b> Mauerfall · <b>3. Okt 1990</b> Wiedervereinigung (Feiertag!) · <b>8. Mai 1945</b> Kriegsende</li>
      <li><b>16</b> Bundesländer · Bundestagswahl alle <b>4 Jahre</b> · wählen ab <b>18</b> · Schulpflicht ab <b>6</b></li>
      <li>Bundeskanzler/in wird vom <b>Bundestag</b> gewählt; Staatsoberhaupt ist der/die <b>Bundespräsident/in</b> (gewählt von der Bundesversammlung)</li>
      <li>Gewaltenteilung: <b>Legislative</b> (Parlament) · <b>Exekutive</b> (Regierung/Polizei) · <b>Judikative</b> (Gerichte). „Direktive“ gibt es nicht!</li>
      <li>Erststimme = <b>Person</b> im Wahlkreis · Zweitstimme = <b>Partei</b> (entscheidet Sitzverteilung) · <b>5%-Hürde</b></li>
      <li>Deutschland: <b>demokratischer + sozialer Bundesstaat</b> · Rechtsstaat = <b>Staat ist an Gesetze gebunden</b></li>
      <li><b>9 Nachbarländer</b> (u.a. Polen, Dänemark, Luxemburg, Tschechien, Österreich). Beliebte Fangfrage: die <b>Schweiz</b> ist Nachbar, aber <b>nicht in der EU</b> – Österreich schon.</li>
      <li>Wappen: <b>Bundesadler</b> (gelb/schwarz) = BRD · <b>Hammer &amp; Zirkel im Ährenkranz</b> = DDR · <b>Sterne auf Blau</b> = EU-Flagge</li>
      <li>Sozialversicherung: Kranken-, Pflege-, Renten-, Unfall- und <b>Arbeitslosenversicherung</b> – keine „Autoversicherung“!</li>
    </ul>
  </section>

  <section class="card">
    <h2>Daten</h2>
    <div class="btnrow">
      <button class="btn btn-ghost" id="btn-export">Fortschritt exportieren</button>
      <button class="btn btn-ghost" id="btn-import">Importieren</button>
    </div>
    <input type="file" id="import-file" accept="application/json" class="hidden">
    <button class="btn btn-danger" id="btn-reset">Fortschritt zurücksetzen</button>
  </section>

  <section class="card about">
    <h2>Über</h2>
    <p>Open Source, ohne Server – alles bleibt auf deinem Gerät. Fragenkatalog: BAMF „Gesamtfragenkatalog Leben in Deutschland / Einbürgerungstest“ (Stand 05/2025), aufbereitet aus
    <a href="https://github.com/flexsurfer/einburgerungstest" target="_blank" rel="noopener">flexsurfer/einburgerungstest</a> und
    <a href="https://github.com/leben-in-deutschland/leben-in-deutschland-scrapper" target="_blank" rel="noopener">leben-in-deutschland</a> (beide MIT).</p>
  </section>`;

  document.getElementById('s-state').onchange = (e) => { store.patchSettings({ state: e.target.value }); toast('Bundesland gespeichert'); };
  document.getElementById('s-lang').onchange = (e) => store.patchSettings({ lang: e.target.value });
  document.getElementById('s-date').onchange = (e) => store.patchSettings({ examDate: e.target.value });

  document.getElementById('btn-export').onclick = () => {
    const blob = new Blob([store.exportAll()], { type: 'application/json' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = `lid-fortschritt-${new Date().toISOString().slice(0, 10)}.json`;
    a.click();
    URL.revokeObjectURL(a.href);
  };
  const fileInput = document.getElementById('import-file');
  document.getElementById('btn-import').onclick = () => fileInput.click();
  fileInput.onchange = async () => {
    if (!fileInput.files[0]) return;
    try {
      store.importAll(await fileInput.files[0].text());
      toast('Fortschritt importiert ✓');
      renderMore();
    } catch {
      toast('Import fehlgeschlagen');
    }
  };
  document.getElementById('btn-reset').onclick = () => {
    if (confirm('Wirklich den gesamten Lernfortschritt löschen?')) {
      store.resetProgress();
      toast('Zurückgesetzt');
      render();
    }
  };
}

// ---------------------------------------------------------------- onboarding

function showOnboarding() {
  openOverlay(`
    <div class="ov-body onboarding">
      <p class="eyebrow">Willkommen</p>
      <h1>In welchem Bundesland machst du die Prüfung?</h1>
      <p class="ob-sub">3 der 33 Prüfungsfragen kommen aus deinem Bundesland.</p>
      <div class="stategrid">
        ${Object.entries(STATES).map(([k, v]) => `<button class="statebtn" data-state="${k}">${v}</button>`).join('')}
      </div>
    </div>`, { dismissable: false });
  for (const b of $overlay.querySelectorAll('[data-state]')) {
    b.onclick = () => {
      store.patchSettings({ state: b.dataset.state });
      askExamDate();
    };
  }
}

function askExamDate() {
  const today = new Date().toISOString().slice(0, 10);
  const current = store.settings.examDate;
  const suggested = current >= today ? current
    : new Date(Date.now() + 14 * 24 * 3600 * 1000).toISOString().slice(0, 10);
  $overlay.querySelector('.ov-body').innerHTML = `
    <p class="eyebrow">Fast geschafft</p>
    <h1>Wann ist deine Prüfung?</h1>
    <p class="ob-sub">Daraus berechnet die App deinen Countdown und dein Tagespensum. Später änderbar unter „Mehr“.</p>
    <input type="date" id="ob-date" value="${suggested}" min="${today}">
    <button class="btn btn-primary btn-big" id="ob-done">Los geht's</button>`;
  document.getElementById('ob-done').onclick = () => {
    const val = document.getElementById('ob-date').value;
    if (val) store.patchSettings({ examDate: val });
    closeOverlay();
    render();
  };
}

// ---------------------------------------------------------------- overlay + toast plumbing

let overlayOnClose = null;

function openOverlay(html, opts = {}) {
  $overlay.innerHTML = html;
  $overlay.classList.remove('hidden');
  document.body.classList.add('no-scroll');
  overlayOnClose = opts.onClose || null;
  // delegated: also catches close buttons injected later (results, finish screens)
  $overlay.onclick = (e) => {
    const b = e.target.closest('[data-close]');
    if (!b) return;
    if ($overlay.querySelector('.exam-timer') && !confirm('Simulation wirklich abbrechen?')) return;
    closeOverlay();
    render();
  };
}

function closeOverlay() {
  if (overlayOnClose) overlayOnClose();
  overlayOnClose = null;
  $overlay.classList.add('hidden');
  $overlay.innerHTML = '';
  document.body.classList.remove('no-scroll');
}

let toastTimer;
function toast(msg) {
  let t = document.querySelector('.toast');
  if (!t) {
    t = document.createElement('div');
    t.className = 'toast';
    document.body.appendChild(t);
  }
  t.textContent = msg;
  t.classList.add('show');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => t.classList.remove('show'), 2200);
}

// ---------------------------------------------------------------- boot

async function boot() {
  const res = await fetch('data/questions.json');
  QUESTIONS = await res.json();
  if (!store.settings.state) showOnboarding();
  render();
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('sw.js').catch(() => {});
  }
}

boot();
