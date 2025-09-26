# earthwormMVO

## ~/src/earthwormMVO

Various scripts used in MVO earthworm installation.

## alarm_send_heli.sh

* Sends out *earthworm* alarms.
* Runs on *winston1*.
* Script in *home/wwsuser/earthworm/earthworm_7.10/bin*.
* Triggered by *earthworm* module *sound_alarm*.
* Generates two plots and then sends them by email. 
* Includes a two-minute delay, allowing time for helicorder fragment to be created.
* Runs *alarm_dialler* on *opsproc2* using *ssh*. 

## plot_chans.py

* Creates four-channel waveform plot of last 4 minutes of data.
* Runs on *winston1*.
* Called by *alarm_send_heli.sh*, which includes plot in alarm email.
* Script in */home/mvo/src/obspy*.

## Author(s)

Various

## Version History

* 1.0-dev
    * Working version

## License

This project is the property of Montserrat Volcano Observatory.
