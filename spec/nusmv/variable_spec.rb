require 'spec_helper'
require 'falluto/nusmv'

describe 'a NuSMV Variable' do
  before do
  end

  it 'should have a name and type' do
    var = Falluto::NuSMV::Variable.new 'procvar', 'SomeProcType'
    var.name.should.equal 'procvar'
    var.type.should.equal 'SomeProcType'
  end

  it 'should raise an error if name is nil or empty' do
    lambda { Falluto::NuSMV::Variable.new nil, 'sometype' }.
      should.raise(Exception).
        message.should.match(/name cannot be empty/)
    lambda { Falluto::NuSMV::Variable.new '', 'sometype' }.
      should.raise(Exception).
        message.should.match(/name cannot be empty/)
  end

  it 'should raise an error if type is nil or empty' do
    lambda { Falluto::NuSMV::Variable.new 'somename', nil }.
      should.raise(Exception).
        message.should.match(/type cannot be empty/)
    lambda { Falluto::NuSMV::Variable.new 'somename', '' }.
      should.raise(Exception).
        message.should.match(/type cannot be empty/)
  end
end

