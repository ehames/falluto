require 'spec_helper'
require 'falluto/nusmv'

describe 'a NuSMV Module' do
  before do
    @module = Falluto::NuSMV::Module.new 'SomeModule'
  end

  it 'should have a name' do
    @module.name.should.equal 'SomeModule'
  end
end
