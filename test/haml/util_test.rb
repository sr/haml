#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../test_helper'
require 'pathname'

class UtilTest < Test::Unit::TestCase
  include Haml::Util

  def test_scope
    assert(File.exist?(scope("Rakefile")))
  end

  def test_to_hash
    assert_equal({
        :foo => 1,
        :bar => 2,
        :baz => 3
      }, to_hash([[:foo, 1], [:bar, 2], [:baz, 3]]))
  end

  def test_map_keys
    assert_equal({
        "foo" => 1,
        "bar" => 2,
        "baz" => 3
      }, map_keys({:foo => 1, :bar => 2, :baz => 3}) {|k| k.to_s})
  end

  def test_map_vals
    assert_equal({
        :foo => "1",
        :bar => "2",
        :baz => "3"
      }, map_vals({:foo => 1, :bar => 2, :baz => 3}) {|k| k.to_s})
  end

  def test_map_hash
    assert_equal({
        "foo" => "1",
        "bar" => "2",
        "baz" => "3"
      }, map_hash({:foo => 1, :bar => 2, :baz => 3}) {|k, v| [k.to_s, v.to_s]})
  end

  def test_powerset
    return unless Set[Set[]] == Set[Set[]] # There's a bug in Ruby 1.8.6 that breaks nested set equality
    assert_equal([[].to_set].to_set,
      powerset([]))
    assert_equal([[].to_set, [1].to_set].to_set,
      powerset([1]))
    assert_equal([[].to_set, [1].to_set, [2].to_set, [1, 2].to_set].to_set,
      powerset([1, 2]))
    assert_equal([[].to_set, [1].to_set, [2].to_set, [3].to_set,
        [1, 2].to_set, [2, 3].to_set, [1, 3].to_set, [1, 2, 3].to_set].to_set,
      powerset([1, 2, 3]))
  end

  def test_restrict
    assert_equal(0.5, restrict(0.5, 0..1))
    assert_equal(1, restrict(2, 0..1))
    assert_equal(1.3, restrict(2, 0..1.3))
    assert_equal(0, restrict(-1, 0..1))
  end

  def test_merge_adjacent_strings
    assert_equal(["foo bar baz", :bang, "biz bop", 12],
      merge_adjacent_strings(["foo ", "bar ", "baz", :bang, "biz", " bop", 12]))
  end

  def test_intersperse
    assert_equal(["foo", " ", "bar", " ", "baz"],
      intersperse(%w[foo bar baz], " "))
    assert_equal([], intersperse([], " "))
  end

  def test_substitute
    assert_equal(["foo", "bar", "baz", 3, 4],
      substitute([1, 2, 3, 4], [1, 2], ["foo", "bar", "baz"]))
    assert_equal([1, "foo", "bar", "baz", 4],
      substitute([1, 2, 3, 4], [2, 3], ["foo", "bar", "baz"]))
    assert_equal([1, 2, "foo", "bar", "baz"],
      substitute([1, 2, 3, 4], [3, 4], ["foo", "bar", "baz"]))

    assert_equal([1, "foo", "bar", "baz", 2, 3, 4],
      substitute([1, 2, 2, 2, 3, 4], [2, 2], ["foo", "bar", "baz"]))
  end

  def test_strip_string_array
    assert_equal(["foo ", " bar ", " baz"],
      strip_string_array([" foo ", " bar ", " baz "]))
    assert_equal([:foo, " bar ", " baz"],
      strip_string_array([:foo, " bar ", " baz "]))
    assert_equal(["foo ", " bar ", :baz],
      strip_string_array([" foo ", " bar ", :baz]))
  end

  def test_silence_warnings
    old_stderr, $stderr = $stderr, StringIO.new
    warn "Out"
    assert_equal("Out\n", $stderr.string)
    silence_warnings {warn "In"}
    assert_equal("Out\n", $stderr.string)
  ensure
    $stderr = old_stderr
  end

  def test_has
    assert(has?(:instance_method, String, :chomp!))
    assert(has?(:private_instance_method, Haml::Engine, :set_locals))
  end

  def test_enum_with_index
    assert_equal(%w[foo0 bar1 baz2],
      enum_with_index(%w[foo bar baz]).map {|s, i| "#{s}#{i}"})
  end

  def test_enum_consr
    assert_equal(%w[foobar barbaz],
      enum_cons(%w[foo bar baz], 2).map {|s1, s2| "#{s1}#{s2}"})
  end

  def test_caller_info
    assert_equal(["/tmp/foo.rb", 12, "fizzle"], caller_info("/tmp/foo.rb:12: in `fizzle'"))
    assert_equal(["/tmp/foo.rb", 12, nil], caller_info("/tmp/foo.rb:12"))
    assert_equal(["(haml)", 12, "blah"], caller_info("(haml):12: in `blah'"))
    assert_equal(["", 12, "boop"], caller_info(":12: in `boop'"))
    assert_equal(["/tmp/foo.rb", -12, "fizzle"], caller_info("/tmp/foo.rb:-12: in `fizzle'"))
  end

  def test_def_static_method
    klass = Class.new
    def_static_method(klass, :static_method, [:arg1, :arg2],
      :sarg1, :sarg2, <<RUBY)
      s = "Always " + arg1
      s << " <% if sarg1 %>and<% else %>but never<% end %> " << arg2

      <% if sarg2 %>
        s << "."
      <% end %>
RUBY
    c = klass.new
    assert_equal("Always brush your teeth and comb your hair.",
      c.send(static_method_name(:static_method, true, true),
        "brush your teeth", "comb your hair"))
    assert_equal("Always brush your teeth and comb your hair",
      c.send(static_method_name(:static_method, true, false),
        "brush your teeth", "comb your hair"))
    assert_equal("Always brush your teeth but never play with fire.",
      c.send(static_method_name(:static_method, false, true),
        "brush your teeth", "play with fire"))
    assert_equal("Always brush your teeth but never play with fire",
      c.send(static_method_name(:static_method, false, false),
        "brush your teeth", "play with fire"))
  end
end
