chai = require("chai")
expect = chai.expect
isCoffee = require './isCoffee'

describe "main", ->
  it "should export all public classes",->
    if isCoffee
      npmExports = require "../../src/main"
    else
      npmExports = require "../../lib/main"
    expect(npmExports).to.be.an 'object'
    expect(npmExports.Spacejam).to.be.a 'function'
    expect(npmExports.Meteor).to.be.a 'function'
    expect(npmExports.PhantomjsRunner).to.be.a 'function'
