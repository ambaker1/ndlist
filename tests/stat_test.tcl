
puts "Basic list statistics"

test stats {
    # Test out every stats function
} -body {
    set a {-5 3 4 0}
    assert [max $a] == 4
    assert [min $a] == -5
    assert [sum $a] == 2
    assert [product $a] == 0
    assert [mean $a] == 0.5
    assert [median $a] == 1.5
    assert [stdev $a] == 4.041451884327381
    assert [variance $a] == 16.333333333333332
    assert [stdev $a 1] == 3.5
    assert [variance $a 1] == 12.25
} -result {}

test stat_errors {
    # Test out bounds of functions
} -body {
    set noArgs {}
    set oneArg {1}
    set twoArgs {1 2}
    # Normal stats 
    foreach func {max min sum product mean median} {
        assert [catch {$func $noArgs}]
        assert ![catch {$func $oneArg}]
        assert ![catch {$func $twoArgs}]
    }
    # Sample variance
    foreach func {stdev variance} {
        assert [catch {$func $noArgs}]
        assert [catch {$func $oneArg}]
        assert ![catch {$func $twoArgs}]
    }
    # Population variance
    foreach func {stdev variance} {
        assert [catch {$func $noArgs 1}]
        assert ![catch {$func $oneArg 1}]
        assert ![catch {$func $twoArgs 1}]
    }
}