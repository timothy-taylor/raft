Engine_Ocean : CroneEngine {
        var <synth;
	var amp=0.1;
	var lfo=8;

        *new { arg context, doneCallback;
                ^super.new(context, doneCallback);
        }
        
        alloc { 
		SynthDef(\ocean, { |out, amp=1, lfo=8|
			var noise, x;
                        noise = WhiteNoise.ar(mul: 0.5, add: 0.1);
                        x = LPF.ar(in: noise, freq: SinOsc.kr(1/lfo).range(100,800));
			x = x + Splay.ar(FreqShift.ar(x, 1/(4..7)));
 
                        Out.ar(out, (x * amp));
		}).add;

		context.server.sync;
		
                synth = Synth.new(\ocean, [
			\out, context.out_b.index, 
			\amp, 0.1, 
			\lfo, 8], 
		context.xg);

		this.addCommand("amp", "f", { |msg|
			synth.set(\amp, msg[1]);
		});

		this.addCommand("lfo", "f", { |msg|
			synth.set(\lfo, msg[1]);
		});
        }
        
        free {
                synth.free;
        }
}
