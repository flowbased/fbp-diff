
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

describe 'fbp-diff', ->
  describe 'with non-existant files', ->
    it 'should exit with error', (done) ->
      fbpDiff 'nonexist.fbp', 'nonexist.json', {}, (err, streams) ->
        chai.expect(err).to.exist
        chai.expect(streams.stderr).to.contain 'no such file'
        chai.expect(streams.stderr).to.contain 'nonexist.'
        done()
