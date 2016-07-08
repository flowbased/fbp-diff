
chai = require 'chai'

fbpDiff = (a, b, options = {}, callback) ->
  childProcess = require 'child_process'
  path = require 'path'

  prog = path.join __dirname, '../bin', 'fbp-diff'
  args = [a, b]
  cmd = prog + ' ' + args.join(' ')
  console.log cmd
  child = childProcess.execFile prog, args, (err, stdout, stderr) ->
    s = { stdout: stdout, stderr: stderr }
    return callback err, s

fixture = (p) ->
  path = require 'path'
  return path.join __dirname, 'fixtures', p

describe 'fbp-diff', ->
  describe 'with non-existant files', ->
    it 'should exit with error', (done) ->
      fbpDiff 'nonexist.fbp', 'nonexist.json', {}, (err, streams) ->
        chai.expect(err).to.exist
        chai.expect(streams.stderr).to.contain 'no such file'
        chai.expect(streams.stderr).to.contain 'nonexist.'
        done()

  describe 'with two .fbp files with changes', ->
    output = ''
    it 'should succeed', (done) ->
      a = fixture 'fbp-git-diff-nZC2/from.PortalLights.fbp'
      b = fixture 'fbp-git-diff-nZC2/to.PortalLights.fbp'
      fbpDiff a, b, {}, (err, streams) ->
        chai.expect(err).to.not.exist
        output = streams.stdout
        done()
    it 'stdout should contain a diff', ->
      chai.expect(output).to.be.a 'string'
      chai.expect(output).to.contain '- "true" -> HWSPI ledchain'
      chai.expect(output).to.contain '- OUTPORT=ledchain.PIXELSET:PIXELSET'
