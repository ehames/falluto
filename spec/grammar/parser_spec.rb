require 'spec_helper'
require 'falluto/grammar'

describe 'a Falluto Parser' do
  before do
    @parser = Falluto::GrammarParser.new
  end

  it 'should parse a simple module' do
    tree = @parser.parse %q{
      MODULE main
    }
    tree.should.not.be.nil
  end

  it 'should parse a module with a variable' do
    tree = @parser.parse %q{
      MODULE main
      VAR
        x : boolean;
    }
    tree.should.not.be.nil
  end

  it 'should parse a fault declaration' do
    @parser.root = :fault
    declaration = @parser.parse %q{FAULT f
         pre(true);
         effect(x = 0, y = 1);
         restores(false);
    }
    declaration.should.not.be.nil
    declaration.name.should.equal 'f'
    declaration.precondition.should.equal 'true'
    declaration.restores.should.equal 'false'
    declaration.effect.should.equal 'x' => '0', 'y' => '1'
  end

  it 'should parse a module with a fault' do
    tree = @parser.parse %q{
      MODULE main
      FAULT f
        pre(cond1 & cond2 | cond3);
        effect(x = x + 1);
        restores(!reset);
      VAR
        x : boolean;
    }
    tree.should.not.be.nil
  end

  it 'should parse a module with two faults' do
    tree = @parser.parse %q{
      MODULE main
      FAULT f
        pre(cond1 & cond2 | cond3);
        effect(x = x + 1);
        restores(!reset);
      FAULT g
        pre(cond1 & cond2 | cond3);
        effect(x = x + 1);
        restores(!reset);
      VAR
        x : boolean;
    }
    tree.should.not.be.nil
  end

  it 'should parse a module with a fault in next assignment' do
    tree = @parser.parse %q{
      MODULE main
      FAULT f
        pre(cond1 & cond2 | cond3);
        effect(x = x + 1);
        restores(!reset);
      VAR
        x : boolean;
      ASSIGN
        next(x) := x + 1 disabled_by {f};
    }
    tree.should.not.be.nil
  end

  it 'should parse a module with a fault in case assignment' do
    tree = @parser.parse %q{
      MODULE main
      FAULT f
        pre(cond1 & cond2 | cond3);
        effect(x = x + 1);
        restores(!reset);
      VAR
        x : boolean;
      ASSIGN
        next(x) :=
          case
            c1 : x + 1;
            1  : x;
          esac disabled_by {f};
    }
    tree.should.not.be.nil
  end

  it 'should parse a module with a fault in case element' do
    tree = @parser.parse %q{
      MODULE main
      FAULT f
        pre(cond1 & cond2 | cond3);
        effect(x = x + 1);
        restores(!reset);
      VAR
        x : boolean;
      ASSIGN
        next(x) :=
          case
            c1 : x + 1 disabled_by {f};
            1  : x;
          esac;
    }
    tree.should.not.be.nil
  end
end
