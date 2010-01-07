require 'spec_helper'
require 'falluto/nusmv'

describe 'a NuSMV Code Generator' do
  before do
    @generator = Falluto::NuSMV::CodeGenerator.new
  end

  it 'should generate a module' do
    @generator.module('main(a, b)').should.equal 'MODULE main(a, b)'
  end

  it 'should generate a variable' do
    @generator.variable_declaration('v', 'boolean').should.equal 'VAR v : boolean;'
  end

  it 'should instance a process' do
    @generator.instance_process('no_params').should.equal 'process no_params();'
    @generator.instance_process('sometype', 'arg1', 'arg2').should.equal 'process sometype(arg1, arg2);'
  end

  it 'should generate a process' do
    @generator.process('sometype()').should.equal 'process sometype()'
  end

  it 'should generate a fairness constraint' do
    @generator.fairness('running').should.equal 'FAIRNESS running'
  end

  it 'should generate macros' do
    @generator.define('v', 'expr').should.equal 'DEFINE v := (expr);'
  end

  it 'should generate an LTL spec' do
    @generator.ltlspec('G F p').should.equal 'LTLSPEC G F p'
  end

  it 'should generate implication' do
    @generator.implies('p', 'q').should.equal '((p) -> (q))'
  end
end

