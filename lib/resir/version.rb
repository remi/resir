class Resir

  module VERSION
    MAJOR = 0
    MINOR = 1
    TINY  = 0
    SCM   = `git log --pretty=oneline | wc -l`.strip

    STRING = [MAJOR, MINOR, TINY, SCM].join('.')
  end

end