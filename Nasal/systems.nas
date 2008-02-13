####	DHC6 systems	####
aircraft.livery.init("Aircraft/dhc6/Models/Liveries", "sim/model/livery/name", "sim/model/livery/index");
var w_fctr=0;
var pph1 = 0.0;
var pph2 = 0.0;
var fuel_density=0.0;
var ViewNum = 0.0;
S_volume = "sim/sound/E_volume";
C_volume = "sim/sound/cabin";
var Oiltemp1="engines/engine[0]/oil-temp-c";
var Oiltemp2="engines/engine[1]/oil-temp-c";
Wiper=[];
var FHmeter = aircraft.timer.new("/instrumentation/clock/flight-meter-sec", 10);

#usage :     var wiper = Wiper.new(wiper property , wiper power source (separate from on off switch));
#
#    var wiper = Wiper.new("controls/electric/wipers","systems/electrical/outputs/wiper");

var Wiper = {
    new : func {
        m = { parents : [Wiper] };
        m.direction = 0;
        m.delay_count = 0;
        m.spd_factor = 0;
        m.node = props.globals.getNode(arg[0],1);
        m.power = props.globals.getNode(arg[1],1);
        if(m.power.getValue()==nil)m.power.setDoubleValue(0);
        m.spd = m.node.getNode("arc-sec",1);
        if(m.spd.getValue()==nil)m.spd.setDoubleValue(1);
        m.delay = m.node.getNode("delay-sec",1);
        if(m.delay.getValue()==nil)m.delay.setDoubleValue(0);
        m.position = m.node.getNode("position-norm", 1);
        m.position.setDoubleValue(0);
        m.switch = m.node.getNode("switch", 1);
        if (m.switch.getValue() == nil)m.switch.setBoolValue(0);
        return m;
    },
    active: func{
    if(me.power.getValue()<=5)return;
    var spd_factor = 1/me.spd.getValue();
    var pos = me.position.getValue();
    if(!me.switch.getValue()){
        if(pos <= 0.000)return;
        }
    if(pos >=1.000){
        me.direction=-1;
        }elsif(pos <=0.000){
        me.direction=0;
        me.delay_count+=getprop("/sim/time/delta-realtime-sec");
        if(me.delay_count >= me.delay.getValue()){
            me.delay_count=0;
            me.direction=1;
            }
        }
    var wiper_time = spd_factor*getprop("/sim/time/delta-realtime-sec");
    pos +=(wiper_time * me.direction);
    me.position.setValue(pos);
    }
};

    var wiper = Wiper.new("controls/electric/wipers","systems/electrical/outputs/wipers");

setlistener("/sim/signals/fdm-initialized", func {
    setprop(S_volume,0.3);
    setprop(C_volume,0.3);
    fuel_density=props.globals.getNode("consumables/fuel/tank[0]/density-ppg").getValue();
    setprop("/instrumentation/clock/flight-meter-hour",0);
    setprop("controls/gear/water-rudder-down",0);
    setprop("controls/gear/water-rudder-pos",0);
    setprop(,0);
    print("system  ...Check");
    setprop("controls/engines/engine/condition",0);
    setprop("controls/engines/engine/condition",0);
    setprop("controls/engines/engine[1]/condition",0);
    setprop(Oiltemp1,getprop("environment/temperature-degc"));
    settimer(update_systems, 2);
});

setlistener("/engines/engine/out-of-fuel", func(nf){
    if(nf.getValue() != 0){
        fueltanks = props.globals.getNode("consumables/fuel").getChildren("tank");
        foreach(f; fueltanks) {
            if(f.getNode("selected", 1).getBoolValue()){
                if(f.getNode("level-lbs").getValue() > 0.01){
                    setprop("/engines/engine/out-of-fuel",0);
                }
            }
        }
    }
},0,0);

setlistener("/sim/current-view/view-number", func(vw){
    ViewNum = vw.getValue();
    if(ViewNum == 0){
        setprop(S_volume,0.3);
        setprop(C_volume,0.3);
        }else{
            setprop(S_volume,0.9);
            setprop(C_volume,0.05);
        }
},0,0);

setlistener("/sim/model/start-idling", func(idle){
    var run= idle.getBoolValue();
    if(run){
    Startup();
    }else{
    Shutdown();
    }
},0,0);

setlistener("/gear/gear[1]/wow", func(gr){
    if(gr.getBoolValue()){
    FHmeter.stop();
    }else{FHmeter.start();}
},0,0);


var Startup = func{
setprop("controls/electric/engine[0]/generator",1);
setprop("controls/electric/engine[1]/generator",1);
setprop("controls/electric/avionics-switch",1);
setprop("controls/electric/battery-switch",1);
setprop("controls/electric/inverter-switch",1);
setprop("controls/lighting/instrument-lights",1);
setprop("controls/lighting/nav-lights",1);
setprop("controls/lighting/beacon",1);
setprop("controls/lighting/strobe",1);
setprop("controls/engines/engine[0]/condition-lever",1);
setprop("controls/engines/engine[1]/condition-lever",1);
setprop("controls/engines/engine[0]/mixture",1);
setprop("controls/engines/engine[1]/mixture",1);
setprop("controls/engines/engine[0]/propeller-pitch",1);
setprop("controls/engines/engine[1]/propeller-pitch",1);
setprop("engines/engine[0]/running",1);
setprop("engines/engine[1]/running",1);
}

var Shutdown = func{
setprop("controls/electric/engine[0]/generator",0);
setprop("controls/electric/engine[1]/generator",0);
setprop("controls/electric/avionics-switch",0);
setprop("controls/electric/battery-switch",0);
setprop("controls/electric/inverter-switch",0);
setprop("controls/lighting/instrument-lights",0);
setprop("controls/lighting/nav-lights",0);
setprop("controls/lighting/beacon",0);
setprop("controls/lighting/strobe",0);
setprop("controls/engines/engine[0]/condition-lever",0);
setprop("controls/engines/engine[1]/condition-lever",0);
setprop("controls/engines/engine[0]/mixture",0);
setprop("controls/engines/engine[1]/mixture",0);
setprop("controls/engines/engine[0]/propeller-pitch",0);
setprop("controls/engines/engine[1]/propeller-pitch",0);
setprop("engines/engine[0]/running",0);
setprop("engines/engine[1]/running",0);
}


var update_systems = func {
        var power = getprop("/controls/switches/master-panel");
        pph1 = getprop("/engines/engine[0]/fuel-flow-gph");
        pph2 = getprop("/engines/engine[1]/fuel-flow-gph");
        if(pph1 == nil){pph1 = 6.72;}
        if(pph2 == nil){pph2 = 6.72;}
        setprop("engines/engine[0]/fuel-flow-pph",pph1* fuel_density);
        setprop("engines/engine[1]/fuel-flow-pph",pph2* fuel_density);
    flight_meter();
    oil_temp();
    wiper.active();

    if(getprop("controls/engines/engine[0]/cutoff")){
        setprop("controls/engines/engine[0]/condition",0);
        setprop("engines/engine[0]/running",0);
        }else{
            setprop("controls/engines/engine[0]/condition",getprop("controls/engines/engine[0]/mixture"));
        }
    if(getprop("controls/engines/engine[1]/cutoff")){
        setprop("controls/engines/engine[1]/condition",0);
        setprop("engines/engine[1]/running",0);
    }else{
        setprop("controls/engines/engine[1]/condition",getprop("controls/engines/engine[1]/mixture"));
    }
    if(getprop("controls/gear/water-rudder-down")){
        setprop("controls/gear/water-rudder-pos",getprop("controls/flight/rudder"));
    }else{
        setprop("controls/gear/water-rudder-pos",0);
    }
    settimer(update_systems, 0);
}

var flight_meter = func{
var fmeter = getprop("/instrumentation/clock/flight-meter-sec");
var fminute = fmeter * 0.016666;
var fhour = fminute * 0.016666;
setprop("/instrumentation/clock/flight-meter-hour",fhour);
}


var oil_temp = func{
var Air_temp= getprop("environment/temperature-degc");
var OT1= getprop(Oiltemp1);
if(OT1 == nil)OT1=0;
var OT2= getprop(Oiltemp2);
if(OT2 == nil)OT2=0;

if(getprop("engines/engine[0]/running")){
    if(OT1 < getprop("engines/engine[0]/n2"))setprop(Oiltemp1,OT1+0.01);
    }else{
        if(OT1 > Air_temp)setprop(Oiltemp1,OT1-0.001);
    }

if(getprop("engines/engine[1]/running")){
    if(OT2 < getprop("engines/engine[1]/n2"))setprop(Oiltemp2,OT2+0.01);
    }else{
        if(OT2 > Air_temp)setprop(Oiltemp2,OT2-0.001);
    }
}

