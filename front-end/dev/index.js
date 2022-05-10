const ws = new WebSocket(`ws://${location.host}`) // eslint-disable-line
ws.onerror = function (err) {
  console.log('WebSocket error', err)
}
ws.onopen = function () {
  console.log('WebSocket connection established')
}
ws.onclose = function () {
  console.log('WebSocket connection closed')
}

ws.onmessage = function (event) {
  const data = JSON.parse(event.data)
  if (data.bundle) {
    console.log('Running new bundle')
    runApp(data.bundle)
  }

  if (data.css) {
    runCss(data.css)
  }
}

let lastBundleRecievedAt = Date.now()
const debounceMs = 400

function runApp (bundle) {
  lastBundleRecievedAt = Date.now()
  document.body.innerHTML = ''
  setTimeout(() => {
    if (Date.now() >= lastBundleRecievedAt + debounceMs) {
      document.body.innerHTML = ''
      const script = document.createElement('script')
      script.className = 'bundle'
      script.innerHTML = bundle
      const oldScripts = document.querySelectorAll('script.bundle');

      (oldScripts || []).forEach(el => {
        el.parentNode.removeChild(el)
      })

      const bodyP = document.body.parentElement

      bodyP.removeChild(document.body)

      bodyP.appendChild(document.createElement('body'))

      document.head.appendChild(script)
    }
  }, debounceMs)
}

const styleEl = document.getElementById('video-calls-stylesheet')

function runCss (css) {
  styleEl.innerHTML = css
}
