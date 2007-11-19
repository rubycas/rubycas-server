require 'test/unit'
if ARGV[0] == 'local'
	begin
		require '../crypt/ISAAC.rb'
	rescue Exception
		require './crypt/ISAAC.rb'
	end
else
	begin
		require 'crypt/ISAACC'
	rescue Exception
		require './crypt/ISAAC.rb'
	end
end

class TC_ISAAC < Test::Unit::TestCase
	def setup
		assert_nothing_raised("Failed to create a Crypt::ISAAC object.") do
			@generator = Crypt::ISAAC.new
		end
	end

	def testKind
		assert_kind_of(Crypt::ISAAC,@generator,"The created object is not a Crypt::ISAAC or subclass thereof.") 
	end

	def testInteger
		assert_nothing_raised("Failed while generating an integer random number.") do
			mynum = @generator.rand(1000000)
			assert_kind_of(Integer,mynum,"The generator failed to return an integer number in response to @generator.rand(1000000).")
			assert((mynum >= 0),"The generator returned a number that is less than 0 (#{mynum}).")
			assert((mynum < 1000000),"The generator returned a number that is greater than or equal to 1000000 (#{mynum}).")
		end
	end

	def testFloat
		assert_nothing_raised("Failed while generating a floating point random number.") do
			mynum = @generator.rand()
			assert_kind_of(Float,mynum,"The generator failed to return a floating point number in response to @generator.rand().")
			assert((mynum >= 0),"The generator returned a number that is less than 0 (#{mynum}).")
			assert((mynum < 1),"The generator returned a number that is greater than or equal to 1 (#{mynum}).")
		end
	end

	def testIterations
		puts
		count = 0
		assert_nothing_raised("Failed on iteration #{count} while trying to generate 100000 random numbers.") do
			100000.times do
				count += 1
				x = @generator.rand(4294967295)
				print [x].pack('V').unpack('H8') if count % 1000 == 0
				if (count % 7000) == 0
					print "\n"
				else
					print " " if count % 1000 == 0
				end
			end
			puts "\n100000 numbers generated"
		end
	end

	def testDualStreams
		g1 = nil
		g2 = nil
		assert_nothing_raised("Failed to pull numbers from two independent streams.") do
			g1 = Crypt::ISAAC.new
			g2 = Crypt::ISAAC.new
			assert((g1 != g2),"The generators are the same.  This should not happen.")
			1000.times do
				g1.rand(4294967295)
				g2.rand(4294967295)
			end
		end
	end
end
