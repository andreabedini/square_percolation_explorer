import std.array;
import std.stdio;
import std.random;
import std.getopt;

alias int[2] xy;

xy toTheLeft(xy a, xy b) pure {
	return [(1 + a[0] + b[0] + a[1] - b[1]) / 2, (a[1] + b[1] - a[0] + b[0] - 1) / 2];
}

xy toTheRight(xy a, xy b) pure {
	return [(1 + a[0] + b[0] - a[1] + b[1]) / 2, (a[1] + b[1] + a[0] - b[0] - 1) / 2];
}

xy rotateLeft(xy a) pure {
	return [ -a[1], a[0] ];
}

xy rotateRight(xy a) pure {
	return [ a[1], -a[0] ];
}

xy forwardLeft(xy a, xy b) pure {
	xy c = 2 * b[] - a[];
	return toTheLeft(b, c);
}

xy forwardRight(xy a, xy b) pure {
	xy c = 2 * b[] - a[];
	return toTheRight(b, c);
}

unittest {
	assert(toTheLeft([0,0], [0,1]) == [0,0]);
	assert(toTheRight([0,0], [0,1]) == [1,0]);

	assert(forwardLeft([0,0], [0,1]) == [0,1]);
	assert(forwardRight([0,0], [0,1]) == [1,1]);

	assert(toTheLeft([0,0], [1,0]) == [1,0]);
	assert(toTheRight([0,0], [1,0]) == [1,-1]);

	assert(forwardLeft([0,0], [1,0]) == [2,0]);
	assert(forwardRight([0,0], [1,0]) == [2,-1]);
}

version(PERIODIC) {
	xy mod(xy a, int L) pure {
		a = [ a[0] % L, a[1] % L ];
		if (a[0] < 0) a[0] += L;
		if (a[1] < 0) a[1] += L;
		return a;
	}
}

enum color : ubyte { white, black };

double p = 0.5;
uint L = 50;
immutable xy a0 = [0, 0];
immutable xy b0 = [0, 1];
xy a = a0;
xy b = b0;
color[xy] lattice, empty;

color checkFace(xy a) {
	version(FIXED_BOUNDARIES) {
		if (a[0] <= -L/2)
			return color.black;

		if ((a[1] == 0 || a[1] == L) && (a[0] <= 0))
			return color.black;

		if (a[0] >= L/2)
			return color.white;

		if ((a[1] == 0 || a[1] == L) && (a[0] > 0))
			return color.white;				
	} else {
		if (a == toTheLeft(a0, b0))
			return color.black;

		if (a == toTheRight(a0, b0))
			return color.white;
	}

	if (a !in lattice)
		lattice[a] = dice(p, 1-p) ? color.white : color.black;

	return lattice[a];
}

bool finished() {
	version(FIXED_BOUNDARIES) {
		return a == [0, L] && b == [0, L + 1];
	} else version(PERIODIC) {
		return a.mod(L) == a0 && b.mod(L) == b0;
	} else {
		return a == a0 && b == b0;		
	}
}

void step()
{
	xy e = (b[] - a[]);

	auto ttl = forwardLeft(a, b);
	auto ttr = forwardRight(a, b);

	version(PERIODIC) {
		ttl = ttl.mod(L);
		ttr = ttr.mod(L);
	}

	color left = checkFace(ttl);
	color right = checkFace(ttr);

	if (left == color.white && right == color.white) {
		a = b;
		b = rotateLeft(e)[] + a[];
	}

	if (left == color.black && right == color.white) {
		xy c = 2 * b[] - a[];
		a = b;
		b = c;
	}

	if (left == color.white && right == color.black) {
		a = b;
		b = rotateLeft(e)[] + a[];
	}

	if (left == color.black && right == color.black) {
		a = b;
		b = rotateRight(e)[] + a[];
	}

	assert(a != b);
}

unittest {
	assert(checkFace(toTheLeft(a0, b0)) == color.black);
	assert(checkFace(toTheRight(a0, b0)) == color.white);

	p = 0.59;
	L = 30;
	rndGen.seed(5);

	int n = 0;
	do {
		step();
		n = n + 1;
	} while (!finished());

	version(PERIODIC) {
		assert(n == 158);
	} version(FIXED_BOUNDARIES) {
		assert(n == 328);		
	} else {
		assert(n == 776);
	}

	writeln("tests pass");
}

void main(string[] args) {
	uint seed = unpredictableSeed;
	uint n = 0;
	getopt(args,
		"p", &p,
		"n", &n,
		"L", &L,
		"seed", &seed);

	if (n == 0) {
		writeln("Use like: ", args[0], " -p 0.5927 -n 1000 -L 50 --seed 1234");
	}

	stderr.writeln("Seeding random number generator with ", seed);
	rndGen.seed(seed);

	for (uint i = 0; i < n; ++i) {
		a = a0;
		b = b0;

		lattice[toTheLeft(a, b)] = color.black;
		lattice[toTheRight(a, b)] = color.white;

		write("H ");
		write(a[0], " ", a[1], " ");
		do {
			step();
			write(a[0], " ", a[1], " ");
		} while (!finished());
		writeln();
		write("L ");
		foreach (xy a; lattice.byKey) {
			write(a[0], " ", a[1], " ", lattice[a] == color.black ? 0 : 1, " ");
		}
		lattice = empty;
		writeln();
	}
}

