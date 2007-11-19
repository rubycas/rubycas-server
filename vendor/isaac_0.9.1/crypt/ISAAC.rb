module Crypt

	# ISAAC is a fast, strong random number generator.  Details on the
	# algorithm can be found here: http://burtleburtle.net/bob/rand/isaac.html
	# This provides a consistent and capable algorithm for producing
	# independent streams of quality random numbers.

	class ISAAC

		attr_accessor :randrsl, :randcnt
		attr_accessor :mm, :aa, :bb, :cc

		# When a Crypt::ISAAC object is created, it needs to be seeded for
		# random number generation.  If the system has a /dev/urandom file,
		# that will be used to do the seeding by default.  If false is explictly
		# passed when creating the object, it will instead use /dev/random to
		# generate its seeds.  Be warned that this may make for SLOW
		# initialization.
		# If the requested source (/dev/urandom or /dev/random) do not exist,
		# the system will fall back to a simplistic initialization mechanism
		# using the builtin Mersenne Twister PRNG.

		def initialize(noblock = true)
			@mm = []
			@randrsl = []
			# Best initialization of the generator would be by pulling
			# numbers from /dev/random.
			rnd_source = noblock ? '/dev/urandom' : '/dev/random'
			if (FileTest.exist? rnd_source)
				File.open(rnd_source,'r') do |r|
					256.times do |t|
						z = r.read(4)
						x = z.unpack('V')[0]
						@randrsl[t] = x
					end
				end
			else
				# If urandom isn't available, the standard Ruby PRNG makes an
				# adequate fallback.
				256.times do |t|
					@randrsl[t] = Kernel.rand(4294967295)
				end
			end
			randinit(true)
			nil
		end

		# Works just like the standard rand() function.  If called with an
		# integer argument, rand() will return positive random number in
		# the range of 0 to (argument - 1).  If called without an integer
		# argument, rand() returns a positive floating point number less than 1.
  
		def rand(*num)
			if (@randcnt == 1)
				isaac
				@randcnt = 256
			end
			@randcnt -= 1
			if num[0].to_i > 0
				@randrsl[@randcnt].modulo(num[0])
			else
				".#{@randrsl[@randcnt]}".to_f
			end
		end

		def isaac
			i = 0
			x = 0
			y = 0

			@cc += 1
			@bb += @cc
			@bb & 0xffffffff

			while (i < 256) do 
				x = @mm[i]
				@aa = (@mm[(i + 128) & 255] + (@aa^(@aa << 13)) ) & 0xffffffff
				@mm[i] = y = (@mm[(x>>2)&255] + @aa + @bb ) & 0xffffffff
				@randrsl[i] = @bb = (@mm[(y>>10)&255] + x ) & 0xffffffff
				i += 1

				x = @mm[i]
				@aa = (@mm[(i+128)&255] + (@aa^(0x03ffffff & (@aa >> 6))) ) & 0xffffffff
				@mm[i] = y = (@mm[(x>>2)&255] + @aa + @bb ) & 0xffffffff
				@randrsl[i] = @bb = (@mm[(y>>10)&255] + x ) & 0xffffffff
				i += 1

				x = @mm[i]
				@aa = (@mm[(i + 128)&255] + (@aa^(@aa << 2)) ) & 0xffffffff
				@mm[i] = y = (@mm[(x>>2)&255] + @aa + @bb ) & 0xffffffff
				@randrsl[i] = @bb = (@mm[(y>>10)&255] + x ) & 0xffffffff
				i += 1

				x = @mm[i]
				@aa = (@mm[(i+128)&255] + (@aa^(0x0000ffff & (@aa >> 16))) ) & 0xffffffff
				@mm[i] = y = (@mm[(x>>2)&255] + @aa + @bb ) & 0xffffffff
				@randrsl[i] = @bb = (@mm[(y>>10)&255] + x ) & 0xffffffff
				i += 1
			end
		end

		def randinit(flag)
			i = 0
			a = 0
			b = 0
			c = 0
			d = 0
			e = 0
			f = 0
			g = 0
			@aa = @bb = @cc = 0
			a = b = c = d = e = f = g = h = 0x9e3779b9

			while (i < 4) do
				a ^= b<<1; d += a; b += c
				b ^= 0x3fffffff & (c>>2); e += b; c += d
				c ^= d << 8; f += c; d += e
				d ^= 0x0000ffff & (e >> 16); g += d; e += f
				e ^= f << 10; h += e; f += g
				f ^= 0x0fffffff & (g >> 4); a += f; g += h
				g ^= h << 8; b += g; h += a
				h ^= 0x007fffff & (a >> 9); c += h; a += b
				i += 1
			end

			i = 0
			while (i < 256) do
				if (flag)
					a+=@randrsl[i  ].to_i; b+=@randrsl[i+1].to_i;
					c+=@randrsl[i+2]; d+=@randrsl[i+3];
					e+=@randrsl[i+4]; f+=@randrsl[i+5];
					g+=@randrsl[i+6]; h+=@randrsl[i+7];
				end

				a^=b<<11; d+=a; b+=c;
				b^=0x3fffffff & (c>>2);  e+=b; c+=d;
				c^=d<<8;  f+=c; d+=e;
				d^=0x0000ffff & (e>>16); g+=d; e+=f;
				e^=f<<10; h+=e; f+=g;
				f^=0x0fffffff & (g>>4);  a+=f; g+=h;
				g^=h<<8;  b+=g; h+=a;
				h^=0x007fffff & (a>>9);  c+=h; a+=b;
				@mm[i]=a;@mm[i+1]=b; @mm[i+2]=c; @mm[i+3]=d;
				@mm[i+4]=e; @mm[i+5]=f; @mm[i+6]=g; @mm[i+7]=h;
				i += 8
			end

			if flag
				i = 0
				while (i < 256)
					a+=@mm[i  ]; b+=@mm[i+1]; c+=@mm[i+2]; d+=@mm[i+3];
					e+=@mm[i+4]; f+=@mm[i+5]; g+=@mm[i+6]; h+=@mm[i+7];
					a^=b<<11; d+=a; b+=c;
					b^=0x3fffffff & (c>>2);  e+=b; c+=d;
					c^=d<<8;  f+=c; d+=e;
					d^=0x0000ffff & (e>>16); g+=d; e+=f;
					e^=f<<10; h+=e; f+=g;
					f^=0x0fffffff & (g>>4);  a+=f; g+=h;
					g^=h<<8;  b+=g; h+=a;
					h^=0x007fffff & (a>>9);  c+=h; a+=b;
					@mm[i  ]=a; @mm[i+1]=b; @mm[i+2]=c; @mm[i+3]=d;
					@mm[i+4]=e; @mm[i+5]=f; @mm[i+6]=g; @mm[i+7]=h;
					i += 8
				end
			end

  		isaac()
   		@randcnt=256;        # /* prepare to use the first set of results */
		end
	end
end
