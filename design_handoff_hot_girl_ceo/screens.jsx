// All screens + the App composition that mounts them in a DesignCanvas.

// ---------- Shared bits ----------
const Phone = ({ children, className = "" }) => (
  <div className={`phone notch ${className}`}>
    <span className="battery">100%</span>
    <div className="screen">{children}</div>
    <div className="home-indicator"></div>
  </div>
);

const Scenarios = [
  { t: "Asking For A Raise",            s: "Boss said 'so… what did you want to talk about?'" },
  { t: "Telling Mom You're Moving",     s: "She thinks you're 'coming home for a bit'. You're not." },
  { t: "Hard Convo With Him",           s: "He texted 'wyd'. It's been three weeks." },
  { t: "Saying No To Bridesmaid",       s: "Dress is $480. Bachelorette is in Tulum. You're broke." },
  { t: "Sephora Refund Drama",          s: "They sent the wrong shade. Twice." },
];

const ScenariosLow = [
  { t: "Setting A Boundary With Dad",   s: "He's giving unsolicited career advice. Again." },
  { t: "Telling Your Therapist Bye",    s: "Six months in and you're not getting anywhere." },
];

// ============================================================
// DIRECTION 1 — HOT GIRL CEO
// black + hot pink + cream, big bold display, scribble accents
// ============================================================

const D1Home = () => (
  <Phone className="">
    <div className="row" style={{justifyContent:'space-between'}}>
      <div className="eyebrow">01 · home</div>
      <div className="eyebrow">⚙</div>
    </div>
    <div style={{marginTop:10, position:'relative'}}>
      <h1>DON'T<br/><span className="pink">FOLD.</span></h1>
      <span className="scrib-tag" style={{position:'absolute', right:0, top:6, color:'var(--accent)'}}>♡ girlies edition</span>
    </div>
    <div className="eyebrow" style={{marginTop:14}}>pick your hard convo →</div>
    <div className="stack gap-8" style={{marginTop:8}}>
      {Scenarios.slice(0,4).map((sc,i)=>(
        <div key={i} className={`card ${i===0?'hi':''}`}>
          <div className="row" style={{justifyContent:'space-between'}}>
            <div className="ttl">{sc.t}</div>
            <span className="chip acc">↗</span>
          </div>
          <div className="sub">{sc.s}</div>
        </div>
      ))}
    </div>
    <div style={{position:'absolute', bottom:14, left:16, right:16}}>
      <div className="row" style={{justifyContent:'space-between'}}>
        <span className="chip">🔥 5-day streak</span>
        <span className="scrib-tag" style={{color:'var(--accent)'}}>"don't be normal"</span>
      </div>
    </div>
  </Phone>
);

const D1Detail = () => (
  <Phone>
    <div className="row" style={{justifyContent:'space-between'}}>
      <div className="eyebrow">02 · brief</div>
      <span className="chip acc">×</span>
    </div>
    <div style={{marginTop:10}}>
      <div className="eyebrow" style={{color:'var(--accent)'}}>scenario 04</div>
      <h1 style={{fontSize:26}}>Saying No To<br/><span className="pink">Bridesmaid Duty.</span></h1>
    </div>
    <div className="stack gap-10" style={{marginTop:14}}>
      <div className="card hi">
        <div className="eyebrow">your goal</div>
        <div className="ttl" style={{marginTop:4}}>Decline without apologising, hedging, or offering a cheaper version of yes.</div>
      </div>
      <div className="card">
        <div className="eyebrow">the scene</div>
        <div className="sub" style={{marginTop:4}}>It's your college roommate. The dress is $480, the bachelorette is in Tulum, and she's about to FaceTime you 'just to chat'.</div>
      </div>
      <div className="card">
        <div className="eyebrow" style={{color:'var(--accent)'}}>⚠ avoid this</div>
        <div className="sub" style={{marginTop:4}}>
          <div>· "I'll think about it"</div>
          <div>· "things have been crazy"</div>
          <div>· inventing a wedding to skip it</div>
          <div>· half-yes</div>
        </div>
      </div>
    </div>
    <div style={{position:'absolute', bottom:14, left:16, right:16}}>
      <div className="card hi" style={{textAlign:'center', padding:'10px'}}>
        <div className="ttl" style={{color:'var(--accent)'}}>START → hold the line</div>
      </div>
    </div>
  </Phone>
);

const D1Convo = () => (
  <Phone>
    <div className="row" style={{justifyContent:'space-between'}}>
      <div>
        <div className="eyebrow">live · turn 3/8</div>
        <div className="ttl" style={{fontFamily:"Bricolage Grotesque", fontWeight:800, fontSize:16, marginTop:2}}>Bridesmaid Duty</div>
      </div>
      <span className="chip">×</span>
    </div>
    <div className="row" style={{marginTop:10, gap:10}}>
      <div style={{flex:1}}>
        <div className="eyebrow">pressure</div>
        <div className="sb-bar" style={{color:'var(--accent)', marginTop:3}}>
          <i className="on"></i><i className="on"></i><i className="on"></i><i></i><i></i>
        </div>
      </div>
      <div style={{flex:1}}>
        <div className="eyebrow">confidence</div>
        <div className="sb-bar" style={{color:'var(--ink)', marginTop:3}}>
          <i className="on"></i><i className="on"></i><i></i><i></i><i></i>
        </div>
      </div>
    </div>
    <div className="stack gap-8" style={{marginTop:14}}>
      <div className="msg them">
        <div style={{width:18,height:18,borderRadius:'50%',background:'var(--accent)',flex:'0 0 auto'}}></div>
        <div className="bubble" style={{background:'#f0f0f0'}}>babe i literally can't get married without you 😭 it's just one dress</div>
      </div>
      <div className="msg you">
        <div className="bubble" style={{background:'var(--accent)', color:'#fff'}}>I'm so honoured. I'm not going to be able to do it.</div>
      </div>
      <div className="msg them">
        <div style={{width:18,height:18,borderRadius:'50%',background:'var(--accent)',flex:'0 0 auto'}}></div>
        <div className="bubble" style={{background:'#f0f0f0'}}>wait what?? is it the money i can help with the dress</div>
      </div>
      <div className="msg you">
        <div className="bubble" style={{background:'#ffd6e6', color:'var(--ink)', border:'1.5px dashed var(--ink)'}}>
          <span style={{opacity:.5}}>...typing</span>
        </div>
      </div>
    </div>
    <div style={{position:'absolute', bottom:16, left:16, right:16}}>
      <div className="row" style={{gap:8}}>
        <div className="inputbar" style={{flex:1}}>type if speaking feels like too much…</div>
        <div className="mic" style={{borderColor:'var(--accent)', background:'var(--accent)', color:'#fff'}}>●</div>
      </div>
    </div>
  </Phone>
);

const D1Result = () => (
  <Phone>
    <div className="row" style={{justifyContent:'space-between'}}>
      <div className="eyebrow">10 · result</div>
      <div className="eyebrow">share ↗</div>
    </div>
    <div style={{marginTop:18, textAlign:'center'}}>
      <div className="eyebrow" style={{color:'var(--accent)'}}>your drop · 24 may 2026</div>
      <h1 style={{fontSize:44, marginTop:6}}>DON'T<br/><span className="pink">FOLD.</span></h1>
      <div className="eyebrow" style={{marginTop:8}}>bridesmaid duty</div>
    </div>
    <div className="card hi" style={{marginTop:14, textAlign:'center'}}>
      <div className="eyebrow">verdict</div>
      <div style={{fontFamily:'Bricolage Grotesque', fontWeight:800, fontSize:24, lineHeight:1, marginTop:6, color:'var(--accent)'}}>HOT GIRL<br/>HELD HER GROUND</div>
    </div>
    <div className="row" style={{marginTop:12, gap:10}}>
      <div className="card" style={{flex:1, textAlign:'center'}}>
        <div className="eyebrow">pressure</div>
        <div style={{fontFamily:'Bricolage Grotesque', fontWeight:800, fontSize:30, marginTop:2}}>62</div>
      </div>
      <div className="card hi" style={{flex:1, textAlign:'center'}}>
        <div className="eyebrow">confidence</div>
        <div style={{fontFamily:'Bricolage Grotesque', fontWeight:800, fontSize:30, marginTop:2, color:'var(--accent)'}}>88</div>
      </div>
    </div>
    <div style={{position:'absolute', bottom:14, left:16, right:16}}>
      <div className="card" style={{textAlign:'center', padding:'10px'}}>
        <div className="ttl">SAVE IMAGE ✦ POST IT ✦ AGAIN</div>
      </div>
    </div>
  </Phone>
);

// ============================================================
// DIRECTION 2 — SOFT POWER
// cream + cherry + dusty rose, italic serif, editorial
// ============================================================

const D2Home = () => (
  <Phone>
    <div className="row" style={{justifyContent:'space-between'}}>
      <div className="eyebrow">No. 01 · home</div>
      <div className="eyebrow" style={{color:'var(--cherry)'}}>✿</div>
    </div>
    <div style={{marginTop:14}}>
      <div className="eyebrow">a quiet field guide to</div>
      <h1><span className="red">Not</span> folding,</h1>
      <h1 style={{marginTop:-2}}>actually.</h1>
    </div>
    <div className="eyebrow" style={{marginTop:14}}>this week's rehearsals</div>
    <div className="stack gap-8" style={{marginTop:8}}>
      {Scenarios.slice(0,4).map((sc,i)=>(
        <div key={i} className={`card ${i===1?'hi':''}`}>
          <div className="row" style={{justifyContent:'space-between'}}>
            <div className="ttl">{sc.t}</div>
            <span style={{fontFamily:'Instrument Serif', fontStyle:'italic', color:'var(--cherry)'}}>→</span>
          </div>
          <div className="sub">{sc.s}</div>
        </div>
      ))}
    </div>
    <div style={{position:'absolute', bottom:14, left:16, right:16, textAlign:'center'}}>
      <div className="eyebrow" style={{color:'var(--cherry)'}}>· · ·</div>
      <div style={{fontFamily:"Cormorant Garamond", fontStyle:'italic', fontSize:14, color:'var(--ink)'}}>"speak gently. mean every word."</div>
    </div>
  </Phone>
);

const D2Detail = () => (
  <Phone>
    <div className="row" style={{justifyContent:'space-between'}}>
      <div className="eyebrow">No. 02 · brief</div>
      <span style={{fontFamily:'Instrument Serif', fontStyle:'italic'}}>×</span>
    </div>
    <div style={{marginTop:12}}>
      <div className="eyebrow">scene 04</div>
      <h1 style={{fontSize:32}}><span className="red">Saying no</span><br/>to bridesmaid<br/>duty.</h1>
    </div>
    <div className="stack gap-10" style={{marginTop:14}}>
      <div className="card hi">
        <div className="eyebrow">your aim</div>
        <div className="ttl" style={{marginTop:2}}>To decline without apology, hedge, or counter-offer.</div>
      </div>
      <div className="card">
        <div className="eyebrow">the scene</div>
        <div className="sub" style={{marginTop:4}}>Your college roommate. $480 dress. Tulum bachelorette. She will, in three minutes, FaceTime you 'just to chat'.</div>
      </div>
      <div className="card">
        <div className="row" style={{gap:8}}>
          <div className="seal">no</div>
          <div className="eyebrow" style={{flex:1}}>refuse, gently</div>
        </div>
        <div className="sub" style={{marginTop:6}}>
          <div>i. no thinking-about-it</div>
          <div>ii. no "things have been busy"</div>
          <div>iii. no inventing a conflict</div>
        </div>
      </div>
    </div>
    <div style={{position:'absolute', bottom:14, left:16, right:16}}>
      <div className="card hi" style={{textAlign:'center'}}>
        <span style={{fontFamily:'Instrument Serif', fontStyle:'italic', fontSize:18, color:'var(--cherry)'}}>begin · hold the line</span>
      </div>
    </div>
  </Phone>
);

const D2Convo = () => (
  <Phone>
    <div className="row" style={{justifyContent:'space-between', alignItems:'flex-start'}}>
      <div>
        <div className="eyebrow">in session · turn 3/8</div>
        <div className="ttl" style={{fontSize:18, marginTop:2}}>Bridesmaid Duty</div>
      </div>
      <span style={{fontFamily:'Instrument Serif', fontStyle:'italic'}}>×</span>
    </div>
    <div className="row" style={{marginTop:10, gap:10}}>
      <div style={{flex:1}}>
        <div className="eyebrow">pressure</div>
        <div style={{fontFamily:'Instrument Serif', fontStyle:'italic', fontSize:22, color:'var(--cherry)'}}>54 <span style={{fontSize:12, opacity:.5}}>/100</span></div>
      </div>
      <div style={{flex:1}}>
        <div className="eyebrow">poise</div>
        <div style={{fontFamily:'Instrument Serif', fontStyle:'italic', fontSize:22}}>41 <span style={{fontSize:12, opacity:.5}}>/100</span></div>
      </div>
    </div>
    <div className="stack gap-8" style={{marginTop:12}}>
      <div className="msg them">
        <div style={{width:18,height:18,borderRadius:'50%',background:'var(--rose)',flex:'0 0 auto', border:'1.5px solid var(--ink)'}}></div>
        <div className="bubble" style={{background:'#fffaf2', border:'1.5px solid var(--ink)'}}>babe i literally can't get married without you 😭 it's just one dress</div>
      </div>
      <div className="msg you">
        <div className="bubble" style={{background:'var(--cherry)', color:'var(--bg)'}}>I'm honoured you asked. I'm not going to be able to do it.</div>
      </div>
      <div className="msg them">
        <div style={{width:18,height:18,borderRadius:'50%',background:'var(--rose)',flex:'0 0 auto', border:'1.5px solid var(--ink)'}}></div>
        <div className="bubble" style={{background:'#fffaf2', border:'1.5px solid var(--ink)'}}>wait what?? is it money — i can help</div>
      </div>
      <div className="msg you">
        <div className="bubble" style={{background:'var(--blush)', border:'1.5px solid var(--ink)'}}>
          <span style={{opacity:.5, fontStyle:'italic'}}>composing…</span>
        </div>
      </div>
    </div>
    <div style={{position:'absolute', bottom:16, left:16, right:16}}>
      <div className="row" style={{gap:8}}>
        <div className="inputbar" style={{flex:1, borderStyle:'solid', borderColor:'var(--ink)', background:'#fffaf2'}}>write, if you'd rather…</div>
        <div className="mic" style={{borderColor:'var(--cherry)', background:'var(--cherry)', color:'var(--bg)'}}>●</div>
      </div>
    </div>
  </Phone>
);

const D2Result = () => (
  <Phone>
    <div className="row" style={{justifyContent:'space-between'}}>
      <div className="eyebrow">No. 10 · entry</div>
      <div className="eyebrow">share ✿</div>
    </div>
    <div style={{marginTop:16, textAlign:'center'}}>
      <div className="eyebrow">issue · 24 may 2026</div>
      <h1 style={{fontSize:40, marginTop:6}}>The <span className="red">Refusal</span><br/>Diary.</h1>
    </div>
    <div className="card hi" style={{marginTop:14, textAlign:'center', padding:'14px 12px'}}>
      <div className="eyebrow">verdict</div>
      <div style={{fontFamily:'Instrument Serif', fontStyle:'italic', fontSize:28, lineHeight:1, marginTop:6, color:'var(--cherry)'}}>Held, beautifully.</div>
      <div className="sub" style={{marginTop:6, fontFamily:'Cormorant Garamond', fontStyle:'italic'}}>"I'm honoured. I'm not going to be able to do it."</div>
    </div>
    <div className="row" style={{marginTop:12, gap:10}}>
      <div className="card" style={{flex:1}}>
        <div className="eyebrow">pressure</div>
        <div style={{fontFamily:'Instrument Serif', fontStyle:'italic', fontSize:26, marginTop:2}}>62</div>
      </div>
      <div className="card" style={{flex:1, background:'var(--blush)'}}>
        <div className="eyebrow">poise</div>
        <div style={{fontFamily:'Instrument Serif', fontStyle:'italic', fontSize:26, marginTop:2, color:'var(--cherry)'}}>88</div>
      </div>
    </div>
    <div style={{position:'absolute', bottom:14, left:16, right:16, textAlign:'center'}}>
      <div className="eyebrow">save · post · rehearse again</div>
    </div>
  </Phone>
);

// ============================================================
// DIRECTION 3 — BRAT MODE
// chartreuse + black, chunky lowercase, glitchy
// ============================================================

const D3Home = () => (
  <Phone>
    <div className="row" style={{justifyContent:'space-between'}}>
      <div className="eyebrow">01 / home</div>
      <span className="tag">menu</span>
    </div>
    <div style={{marginTop:14}}>
      <h1>don't<br/>fold.</h1>
      <div className="eyebrow" style={{marginTop:4}}>← the <span style={{textDecoration:'line-through'}}>nice</span> girl app</div>
    </div>
    <div className="row" style={{marginTop:12, gap:6, flexWrap:'wrap'}}>
      <span className="tag">today's drill ↓</span>
      <span className="tag" style={{background:'var(--cream)', color:'var(--ink)', border:'2px solid var(--ink)'}}>5🔥 streak</span>
    </div>
    <div className="stack gap-8" style={{marginTop:10}}>
      {Scenarios.slice(0,5).map((sc,i)=>(
        <div key={i} className={`card ${i===2?'hi':''}`}>
          <div className="row" style={{justifyContent:'space-between'}}>
            <div className="ttl">{sc.t.toLowerCase()}</div>
            <span style={{fontFamily:'Space Mono', fontSize:10}}>0{i+1}</span>
          </div>
          <div className="sub" style={{opacity:.85}}>{sc.s}</div>
        </div>
      ))}
    </div>
  </Phone>
);

const D3Detail = () => (
  <Phone>
    <div className="row" style={{justifyContent:'space-between'}}>
      <span className="tag">← back</span>
      <span className="tag">02 / brief</span>
    </div>
    <div style={{marginTop:14}}>
      <div className="eyebrow">drill 03</div>
      <h1 style={{fontSize:32}}>hard convo<br/><span className="x">with him.</span></h1>
    </div>
    <div className="stack gap-10" style={{marginTop:14}}>
      <div className="card hi">
        <div className="eyebrow" style={{color:'var(--bg)'}}>the assignment</div>
        <div className="ttl" style={{marginTop:2}}>tell him you're done — without leaving the door open.</div>
      </div>
      <div className="card">
        <div className="eyebrow">the scene</div>
        <div className="sub" style={{marginTop:2}}>3 weeks of crumbs. He texted 'wyd' at 11:47pm. you opened it on purpose.</div>
      </div>
      <div className="card">
        <div className="eyebrow">don't ↓</div>
        <div className="sub" style={{marginTop:4}}>
          <div>· "i think we should talk"</div>
          <div>· lol</div>
          <div>· "maybe later"</div>
          <div>· any 💀 or 😅</div>
        </div>
      </div>
    </div>
    <div style={{position:'absolute', bottom:14, left:16, right:16}}>
      <div className="card hi" style={{textAlign:'center'}}>
        <div className="ttl" style={{color:'var(--bg)'}}>go off ↗</div>
      </div>
    </div>
  </Phone>
);

const D3Convo = () => (
  <Phone>
    <div className="row" style={{justifyContent:'space-between'}}>
      <div>
        <span className="tag">live · 3/8</span>
        <div className="ttl" style={{marginTop:4, fontSize:14}}>hard convo with him</div>
      </div>
      <span className="tag">×</span>
    </div>
    <div className="row" style={{marginTop:10, gap:8}}>
      <div className="tag" style={{flex:1, textAlign:'center'}}>PRESS 64</div>
      <div className="tag" style={{flex:1, textAlign:'center', background:'var(--accent)', color:'var(--ink)'}}>CONF 38</div>
    </div>
    <div className="stack gap-8" style={{marginTop:12}}>
      <div className="msg them">
        <div style={{width:18,height:18,background:'var(--ink)',flex:'0 0 auto'}}></div>
        <div className="bubble" style={{background:'var(--cream)', border:'2px solid var(--ink)', borderRadius:0}}>wyd</div>
      </div>
      <div className="msg you">
        <div className="bubble" style={{background:'var(--ink)', color:'var(--bg)', borderRadius:0}}>not entertaining this anymore. take care.</div>
      </div>
      <div className="msg them">
        <div style={{width:18,height:18,background:'var(--ink)',flex:'0 0 auto'}}></div>
        <div className="bubble" style={{background:'var(--cream)', border:'2px solid var(--ink)', borderRadius:0}}>damn? all i said was wyd 😭</div>
      </div>
      <div className="msg you">
        <div className="bubble" style={{background:'var(--accent)', color:'var(--ink)', borderRadius:0, border:'2px solid var(--ink)'}}>
          <span style={{opacity:.6}}>typing...</span>
        </div>
      </div>
    </div>
    <div style={{position:'absolute', bottom:14, left:16, right:16}}>
      <div className="row" style={{gap:8}}>
        <div className="inputbar" style={{flex:1, background:'var(--cream)', borderRadius:0, borderStyle:'solid', borderColor:'var(--ink)'}}>type if u can't say it…</div>
        <div className="mic" style={{borderColor:'var(--ink)', background:'var(--ink)', color:'var(--bg)', borderRadius:0}}>●</div>
      </div>
    </div>
  </Phone>
);

const D3Result = () => (
  <Phone>
    <div className="row" style={{justifyContent:'space-between'}}>
      <span className="tag">10 / result</span>
      <span className="tag">share ↗</span>
    </div>
    <div style={{marginTop:14, textAlign:'center'}}>
      <h1 style={{fontSize:46}}>didn't.<br/>fold.</h1>
      <div className="eyebrow" style={{marginTop:4}}>hard convo · 24.05.26</div>
    </div>
    <div className="card hi" style={{marginTop:14, textAlign:'center'}}>
      <div className="eyebrow" style={{color:'var(--bg)'}}>verdict</div>
      <div style={{fontFamily:'Bricolage Grotesque', fontWeight:800, fontSize:24, marginTop:6, color:'var(--accent)', textTransform:'lowercase', lineHeight:1}}>cold, deliberate,<br/>not delulu.</div>
    </div>
    <div className="row" style={{marginTop:10, gap:8}}>
      <div className="card" style={{flex:1, textAlign:'center'}}>
        <div className="eyebrow">press</div>
        <div style={{fontFamily:'Bricolage Grotesque', fontWeight:800, fontSize:30}}>71</div>
      </div>
      <div className="card" style={{flex:1, textAlign:'center', background:'var(--accent)'}}>
        <div className="eyebrow">conf</div>
        <div style={{fontFamily:'Bricolage Grotesque', fontWeight:800, fontSize:30}}>92</div>
      </div>
    </div>
    <div style={{marginTop:10}}>
      <div className="eyebrow">receipts ↓</div>
      <div className="card" style={{marginTop:6}}>
        <div className="sub">"not entertaining this anymore. take care."</div>
      </div>
    </div>
    <div style={{position:'absolute', bottom:14, left:16, right:16}}>
      <div className="row" style={{gap:6}}>
        <span className="tag" style={{flex:1, textAlign:'center', padding:'6px'}}>save</span>
        <span className="tag" style={{flex:1, textAlign:'center', padding:'6px', background:'var(--accent)', color:'var(--ink)'}}>post</span>
        <span className="tag" style={{flex:1, textAlign:'center', padding:'6px'}}>again</span>
      </div>
    </div>
  </Phone>
);

// ============================================================
// APP
// ============================================================

const Note = ({children, style}) => (
  <div style={{
    fontFamily:'Caveat, cursive', fontSize:15, color:'#3a3a3a',
    background:'#fef4a8', padding:'6px 10px', borderRadius:6,
    boxShadow:'2px 2px 0 #1a1815', transform:'rotate(-1.5deg)',
    maxWidth:240, ...style
  }}>{children}</div>
);

const SectionHeader = ({n, title, blurb, accent}) => (
  <div style={{padding:'8px 0 16px', maxWidth:680}}>
    <div style={{fontFamily:'Space Mono, monospace', fontSize:11, letterSpacing:'.2em', textTransform:'uppercase', color:accent}}>
      direction {n}
    </div>
    <div style={{
      fontFamily:'Permanent Marker, cursive',
      fontSize:34, lineHeight:1, marginTop:4, color:'#1a1815'
    }}>{title}</div>
    <div style={{
      fontFamily:'Caveat, cursive', fontSize:19, color:'#3a3a3a',
      marginTop:8, lineHeight:1.25
    }}>{blurb}</div>
  </div>
);

function App() {
  return (
    <DesignCanvas>
      <DCSection
        id="intro"
        title="don't fold · girlies edition"
        subtitle="Wireframes. Same scenario engine, three different aesthetic personalities. Pick one — or mix."
      >
        <DCArtboard id="intro-note" label="brief" width={420} height={260}>
          <div style={{padding:'18px 20px', height:'100%', boxSizing:'border-box', fontFamily:'Patrick Hand', fontSize:14, lineHeight:1.4, color:'#1a1815'}}>
            <div style={{fontFamily:'Permanent Marker', fontSize:22}}>the remix.</div>
            <div style={{marginTop:8}}>
              Original "Don't Fold" → confidence-training in hard conversations.<br/><br/>
              <b>Girlies edition</b> keeps the engine (scenario → brief → live convo → result card) but swaps in girl-coded fights: telling mom you're moving, saying no to bridesmaid duty, hard convos with him, Sephora refund drama.
            </div>
            <div style={{marginTop:12, fontFamily:'Caveat', fontSize:17, color:'#c41e3a'}}>still badass. just hotter. 🔥</div>
          </div>
        </DCArtboard>
        <DCArtboard id="legend" label="legend" width={300} height={260}>
          <div style={{padding:'18px 20px', height:'100%', boxSizing:'border-box', fontFamily:'Patrick Hand', fontSize:13, color:'#1a1815'}}>
            <div style={{fontFamily:'Permanent Marker', fontSize:18}}>3 directions →</div>
            <div style={{marginTop:10, lineHeight:1.5}}>
              <div><b style={{color:'#ff2d87'}}>① HOT GIRL CEO</b> — black + pink, big bold, scribbles</div>
              <div style={{marginTop:6}}><b style={{color:'#c41e3a'}}>② SOFT POWER</b> — cream + cherry, italic serif, quiet & sharp</div>
              <div style={{marginTop:6}}><b style={{color:'#9bcc00'}}>③ BRAT MODE</b> — chartreuse + black, lowercase, club-kid</div>
            </div>
          </div>
        </DCArtboard>
      </DCSection>

      <DCSection
        id="d1"
        title="① HOT GIRL CEO"
        subtitle="Black ink + hot pink. Big bold display. Scribbled affirmations. She is on her way to a meeting and you are in it."
      >
        <DCArtboard id="d1-home"   label="01 · home"     width={300} height={620}><div className="d1"><D1Home/></div></DCArtboard>
        <DCArtboard id="d1-detail" label="02 · brief"    width={300} height={620}><div className="d1"><D1Detail/></div></DCArtboard>
        <DCArtboard id="d1-convo"  label="03 · live"     width={300} height={620}><div className="d1"><D1Convo/></div></DCArtboard>
        <DCArtboard id="d1-result" label="04 · result"   width={300} height={620}><div className="d1"><D1Result/></div></DCArtboard>
      </DCSection>

      <DCSection
        id="d2"
        title="② SOFT POWER"
        subtitle="Cream + cherry red + dusty rose. Italic serif. Editorial. Speaks gently, means every word. Reads like a journal you'd actually keep."
      >
        <DCArtboard id="d2-home"   label="01 · home"     width={300} height={620}><div className="d2"><D2Home/></div></DCArtboard>
        <DCArtboard id="d2-detail" label="02 · brief"    width={300} height={620}><div className="d2"><D2Detail/></div></DCArtboard>
        <DCArtboard id="d2-convo"  label="03 · live"     width={300} height={620}><div className="d2"><D2Convo/></div></DCArtboard>
        <DCArtboard id="d2-result" label="04 · entry"    width={300} height={620}><div className="d2"><D2Result/></div></DCArtboard>
      </DCSection>

      <DCSection
        id="d3"
        title="③ BRAT MODE"
        subtitle="Chartreuse + black. Lowercase everything. Sharp corners. Club-kid energy. The version that goes viral on tiktok."
      >
        <DCArtboard id="d3-home"   label="01 · home"     width={300} height={620}><div className="d3"><D3Home/></div></DCArtboard>
        <DCArtboard id="d3-detail" label="02 · brief"    width={300} height={620}><div className="d3"><D3Detail/></div></DCArtboard>
        <DCArtboard id="d3-convo"  label="03 · live"     width={300} height={620}><div className="d3"><D3Convo/></div></DCArtboard>
        <DCArtboard id="d3-result" label="04 · result"   width={300} height={620}><div className="d3"><D3Result/></div></DCArtboard>
      </DCSection>

      <DCSection
        id="notes"
        title="things to decide next"
        subtitle="If a direction clicks, tell me which one and I'll push it to hi-fi — real type system, real motion, real onboarding."
      >
        <DCArtboard id="open-qs" label="open questions" width={460} height={320}>
          <div style={{padding:'18px 22px', fontFamily:'Patrick Hand', fontSize:14, lineHeight:1.45, color:'#1a1815'}}>
            <div style={{fontFamily:'Permanent Marker', fontSize:18, marginBottom:8}}>still TBD ↓</div>
            <div>· <b>name</b> — keep "Don't Fold." or rename ("No, Actually.", "Backbone.", "Hold The Line.")?</div>
            <div style={{marginTop:6}}>· <b>scenario library</b> — how spicy do we get? (situationship breakups, family boundaries, "telling your friend her bf is cheating"?)</div>
            <div style={{marginTop:6}}>· <b>voice vs text</b> — is the mic the hero, or is it text-first with voice as a flex?</div>
            <div style={{marginTop:6}}>· <b>shareability</b> — result cards as Instagram-story-shaped? TikTok overlay-ready?</div>
            <div style={{marginTop:6}}>· <b>scoring vibe</b> — keep "pressure / confidence" or rename to something cuter ("nerve / nerve held", "pressure / poise")?</div>
          </div>
        </DCArtboard>
      </DCSection>
    </DesignCanvas>
  );
}
