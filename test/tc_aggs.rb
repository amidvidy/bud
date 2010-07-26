class ShortestPaths < Bud
  def initialize(ip, port)
    super(ip,port)
  end
  
  def state
    table :link, ['from', 'to', 'cost']
    table :path, ['from', 'to', 'next', 'cost']
    table :shortest, ['from', 'to'], ['next', 'cost']
    table :minmaxsumcntavg, ['from', 'to'], ['mincost', 'maxcost', 'sumcost', 'cnt', 'avgcost']
  end
  
  def declaration
    strata[0] = rules {
      link << ['a', 'b', 1]
      link << ['a', 'b', 4]
      link << ['b', 'c', 1]
      link << ['c', 'd', 1]
      link << ['d', 'e', 1]

      path <= link.map{|e| [e.from, e.to, e.to, e.cost]}

      j = join [link, path], [path.from, link.to]
      path <= j.map do |l,p|
        [l.from, p.to, p.from, l.cost+p.cost] # if l.to == p.from
      end
    }

    strata[1] = rules {
      shortest <= path.argagg(:min, [path.from, path.to], path.cost)
      minmaxsumcntavg <= path.group([path.from, path.to], min(path.cost), min(path.cost), sum(path.cost), count, avg(path.cost))
    }
  end
end

class TestJoins < Test::Unit::TestCase
  def test_paths
    program = ShortestPaths.new('localhost', 12345)
    assert_nothing_raised( RuntimeError) { program.tick }
    program.minmaxsumcntavg.each do |t|
      assert(t[2] <= t[3])
      assert_equal(t[4]*1.0 / t[5], t[6])
    end
    program.shortest.each do |t|
      assert_equal(t[1][0] - t[0][0], t[3])
    end
  end
end