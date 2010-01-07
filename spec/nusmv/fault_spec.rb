require 'spec_helper'
require 'falluto/nusmv'

describe 'a Falluto Fault' do
  before do
    pre = 'x > 0'
    restore = 'x >= 0'
    effect = nil
    @fault = Falluto::NuSMV::Fault.new 'Foo', 'Bar', pre, restore, effect
  end

  it 'should have a name' do
    @fault.name.should.be.equal 'Bar'
    @fault.process_name.should.be.equal 'Foo_Bar'
  end

end
