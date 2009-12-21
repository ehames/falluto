class NuSMVCodeGenerator
  def define var, expr
    %Q|DEFINE #{var} := (#{expr});|
  end

  def variable_declaration var, type
    %Q|VAR #{var} : #{type};|
  end

  def fairness expr
    %Q|FAIRNESS #{expr}|
  end

  def module signature
    %Q|MODULE #{signature}|
  end

  def process type
    %Q|process #{type}|
  end

  def ltlspec expr
    %Q|LTLSPEC #{expr}|
  end

  def implies(p, q)
    %Q|((#{p}) -> (#{q}))|
  end
end

