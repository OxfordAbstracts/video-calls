const { build } = require('esbuild')
const chokidar = require('chokidar')
const express = require('express')
const ws = require('ws')
const postcss = require('postcss')
const fs = require('fs')
const { promisify } = require('util')
const read = promisify(fs.readFile)
const exec = promisify(require('child_process').exec)
const compression = require('compression')
const keypress = require('keypress')
const config = require('./tailwind.config.js')
const proxy = require('express-http-proxy');

const NS_PER_SEC = 1e9

let rebuildingPurs = false

module.exports = async (port = 8001) => {
  const app = express()

  let builder = await build({
    bundle: true,
    entryPoints: [__dirname + '/dev/entry.js'],
    incremental: true,
    minify: false,
    write: false,
    external: ['xhr2', 'url']
  })

  // Set up a headless websocket server that prints any
  // events that come in.
  const wsServer = new ws.Server({ noServer: true })

  // `server` is a vanilla Node.js HTTP server, so use
  // the same ws upgrade process described here:
  // https://www.npmjs.com/package/ws#multiple-servers-sharing-a-single-https-server
  const server = app.listen(port)
  app.use(compression())

  app.use('/', express.static(__dirname + '/dev'))
  app.use('/api', proxy('http://localhost:3000'));

  let sockets = []

  server.on('upgrade', (request, socket, head) => {
    wsServer.handleUpgrade(request, socket, head, async socket => {
      wsServer.emit('connection', socket, request)
      sockets.push(socket)

      socket.on('close', () => {
        sockets = sockets.filter(s => s !== socket)
      })

      sendBundle(socket)
      try {
        const css = await buildCss()
        await sendCss(css, socket)
      } catch (err) {
        console.error('css build error', err)
      }
    })
  })
  console.log(`development server listening at http://localhost:${port}`)
  console.log('press "r" to rebuild purescript')
  console.log('press "t" to run purescript tests')
  console.log('press "c" to exit')

  const rebuildBundle = async () => {
    if (rebuildingPurs) return
    await sleep(100)
    console.log('Rebuilding bundle...')
    const time = process.hrtime()
    builder = await builder.rebuild()
    sendBundle()
    logTimeTaken(time)
    console.log('Rebuilding css...')
    const cssTime = process.hrtime()
    try {
      const newCss = await buildCss()
      sendCss(newCss)
    } catch (err) {
      console.error('css build error', err)
    }

    logTimeTaken(cssTime)
  }

  chokidar
    // Watches purescript output.
    .watch([__dirname + '/output/**/*.js'], {
      interval: 1000
    })
    .on('change', rebuildBundle)

  chokidar
    // Watches scss output.
    .watch(__dirname + '/css/**/*.css', {
      interval: 1000
    })
    .on('change', async () => {
      console.log('Rebuilding css...')
      const time = process.hrtime()
      const newCss = await buildCss()
      sendCss(newCss)
      logTimeTaken(time)
    })


  // make `process.stdin` begin emitting "keypress" events
  keypress(process.stdin)
  process.stdin.setRawMode(true)

  const pauseAndRunCmd = async (name, cmd) => {
    try {
      rebuildingPurs = true
      console.log(name)
      await exec(cmd)
      console.log('finished ' + name)
      rebuildingPurs = false
      await rebuildBundle()
    } catch (err) {
      console.error('caught keypress rebuild error')
      console.error(err)
      console.error(err.stderr)

      rebuildingPurs = false
    }
  }

  // listen for the "keypress" event
  process.stdin.on('keypress', async (ch, key) => {
    if (key && key.name === 'c') {
      process.exit()
    }

    if (key && key.name === 'r' && !rebuildingPurs) {
      await pauseAndRunCmd('rebuilding purs', 'cd front-end && spago build')
    }
    if (key && key.name === 't' && !rebuildingPurs) {
      await pauseAndRunCmd('testing purs', 'cd front-end && spago test')
    }
  })

  const sendCss = async (css, individualSocket) => {
    if (individualSocket) {
      try {
        for (const out of builder.outputFiles) {
          individualSocket.send(JSON.stringify({ css }))
        }
        return
      } catch (err) {
        console.log('Failed to send bundle to socket: ', err)
      }
    }
    for (const socket of sockets) {
      try {
        socket.send(JSON.stringify({ css }))
      } catch (err) {
        console.error('css send error: ', err)
      }
    }
  }

  const sendBundle = async (individualSocket) => {
    if (individualSocket) {
      try {
        for (const out of builder.outputFiles) {
          individualSocket.send(JSON.stringify({ bundle: decodeArray(out.contents) }))
        }
        return
      } catch (err) {
        console.log('Failed to send bundle to socket: ', err)
      }
    }
    for (const socket of sockets) {
      try {
        for (const out of builder.outputFiles) {
          socket.send(JSON.stringify({ bundle: decodeArray(out.contents) }))
        }
      } catch (err) {
        console.error('bundle build error: ', err)
      }
    }
  }
}

const sleep = ms => {
  return new Promise(resolve => setTimeout(resolve, ms))
}

const buildCss = async () => {
  const toRun = await read(__dirname + '/css/style.css')
  const { css } = await postcss([require('postcss-import'), require('tailwindcss')(config)])
    .process(toRun.toString(), { from: __dirname + '/css/style.css' })

  return css
}

const logTimeTaken = time => {
  const diff = process.hrtime(time)
  console.log(`Rebuild took ${((diff[0] * NS_PER_SEC + diff[1]) / 1e6).toFixed(0)}ms`)
}

const decodeArray = arr => new TextDecoder('utf-8').decode(arr)
