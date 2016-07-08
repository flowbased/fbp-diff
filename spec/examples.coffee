
fbpDiff = require '../'
chai = require 'chai'

testExample = (testcase) ->
  options =
    format: testcase.format or 'fbp'
  it 'should produce a diff', ->
    diff = fbpDiff.diff testcase.from, testcase.to, options
    chai.expect(diff).to.be.a 'string'
  it 'diff should equal expected', ->
    diff = fbpDiff.diff testcase.from, testcase.to, options
    chai.expect(diff).to.equal testcase.diff

loadTestCases = () ->
  # currently node.js only
  fs = require 'fs'
  path = require 'path'
  yaml = require 'js-yaml'

  exampleDir = path.join __dirname  , '..', 'examples'
  files = fs.readdirSync(exampleDir).filter (p) -> p.indexOf('.yml')
  testcases = []
  for f in files
    p = path.join exampleDir, f
    contents = fs.readFileSync p, 'utf-8'
    cases = yaml.safeLoad contents
    for name, c of cases
      c.name = name
      testcases.push c

  return testcases

tests = loadTestCases()

describe 'Examples', ->
  it 'should exist', ->
    chai.expect(tests).to.have.length.above 1

  for testcase in tests
    describeUnlessSkipped = if testcase.skip then describe.skip else describe
    describeUnlessSkipped testcase.name, ->
      testExample testcase
