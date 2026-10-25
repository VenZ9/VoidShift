#!/usr/bin/env python3
"""
VOIDSHIFT - Procedural Audio Generator
Generates original sci-fi sound effects and ambient drone as 16-bit PCM WAV files.
"""

import os
import math
import struct
import wave
import random

SAMPLE_RATE = 44100

def write_wav(filename: str, samples: list[float]):
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with wave.open(filename, 'wb') as wav_file:
        n_channels = 1
        sampwidth = 2 # 16-bit
        framerate = SAMPLE_RATE
        wav_file.setparams((n_channels, sampwidth, framerate, len(samples), 'NONE', 'not compressed'))
        
        packed_data = bytearray()
        for sample in samples:
            # Clamp sample to [-1.0, 1.0]
            val = max(-1.0, min(1.0, sample))
            int_val = int(val * 32767.0)
            packed_data.extend(struct.pack('<h', int_val))
        wav_file.writeframes(packed_data)
    print(f"Generated: {filename} ({len(samples)} samples, {len(samples)/SAMPLE_RATE:.2f}s)")

def generate_grav_shift(path: str):
    # 0.45s gravity shift: heavy sub-bass drop + resonant magnetic servo whoosh + snap
    duration = 0.45
    total_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(total_samples):
        t = i / SAMPLE_RATE
        # Sub-bass pitch sweep: 140Hz down to 40Hz
        freq = 140.0 * (1.0 - t / duration) + 40.0
        sine_phase = 2.0 * math.pi * freq * t
        sub = math.sin(sine_phase)
        
        # Resonant whoosh: frequency modulated noise/saw
        whoosh_env = math.sin(math.pi * (t / duration)) ** 1.5
        whoosh_freq = 300.0 + 500.0 * math.sin(math.pi * t / duration)
        whoosh = math.sin(2.0 * math.pi * whoosh_freq * t) * 0.4 + (random.random() * 2.0 - 1.0) * 0.15
        
        # Metal click at 0.35s
        click = 0.0
        if 0.34 <= t <= 0.38:
            dt = (t - 0.34) / 0.04
            click = math.sin(2.0 * math.pi * 900.0 * (t - 0.34)) * math.exp(-dt * 12.0) * 0.6
        
        env = math.exp(-t * 4.0) * 0.8 + whoosh_env * 0.4
        val = (sub * 0.7 + whoosh * whoosh_env * 0.5 + click) * min(1.0, env)
        samples.append(val)
    write_wav(path, samples)

def generate_laser_shoot(path: str):
    duration = 0.18
    total_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(total_samples):
        t = i / SAMPLE_RATE
        # Fast exponential pitch drop 1600Hz -> 180Hz
        freq = 1600.0 * math.exp(-t * 22.0) + 180.0
        phase = 2.0 * math.pi * freq * t
        # Slightly crunchy square-ish wave
        raw = math.sin(phase) + 0.3 * math.sin(phase * 3.0)
        env = math.exp(-t * 18.0)
        val = raw * env * 0.85
        samples.append(val)
    write_wav(path, samples)

def generate_hit(path: str):
    duration = 0.22
    total_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(total_samples):
        t = i / SAMPLE_RATE
        noise = (random.random() * 2.0 - 1.0) * math.exp(-t * 30.0)
        metal_freq = 320.0 * math.exp(-t * 10.0) + 120.0
        metal = math.sin(2.0 * math.pi * metal_freq * t) * math.exp(-t * 15.0)
        distortion = math.tanh((noise * 1.5 + metal * 1.2) * 1.8) * 0.7
        samples.append(distortion)
    write_wav(path, samples)

def generate_pickup(path: str):
    duration = 0.35
    total_samples = int(SAMPLE_RATE * duration)
    samples = []
    # Two-tone ascending chime
    for i in range(total_samples):
        t = i / SAMPLE_RATE
        if t < 0.1:
            freq = 659.25 # E5
            env = math.exp(-t * 12.0)
        else:
            freq = 987.77 # B5
            env = math.exp(-(t - 0.1) * 8.0)
        harmonic = math.sin(2.0 * math.pi * freq * 2.0 * t) * 0.3
        sine = math.sin(2.0 * math.pi * freq * t) + harmonic
        samples.append(sine * env * 0.7)
    write_wav(path, samples)

def generate_ui_click(path: str):
    duration = 0.04
    total_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(total_samples):
        t = i / SAMPLE_RATE
        freq = 1800.0 * (1.0 - t / duration) + 800.0
        sine = math.sin(2.0 * math.pi * freq * t)
        env = math.exp(-t * 80.0)
        samples.append(sine * env * 0.6)
    write_wav(path, samples)

def generate_door_open(path: str):
    duration = 0.5
    total_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(total_samples):
        t = i / SAMPLE_RATE
        # Pneumatic hiss (filtered noise)
        noise = (random.random() * 2.0 - 1.0) * 0.3
        # Servo motor hum
        servo = math.sin(2.0 * math.pi * 220.0 * t) * 0.25
        env = math.sin(math.pi * (t / duration))
        samples.append((noise + servo) * env * 0.7)
    write_wav(path, samples)

def generate_ambient_drone(path: str):
    # 4.0 second seamlessly loopable ambient station hum
    duration = 4.0
    total_samples = int(SAMPLE_RATE * duration)
    samples = []
    base_f1 = 55.0  # A1
    base_f2 = 110.0 # A2
    base_f3 = 165.0 # E3
    
    for i in range(total_samples):
        t = i / SAMPLE_RATE
        # Ensure exact integer cycles for seamless loop
        cycle_phase = (2.0 * math.pi * i) / total_samples
        
        # Slow LFO pulsation
        lfo = 0.8 + 0.2 * math.sin(cycle_phase * 2.0)
        lfo2 = 0.85 + 0.15 * math.cos(cycle_phase * 3.0)
        
        s1 = math.sin(2.0 * math.pi * base_f1 * t) * 0.5 * lfo
        s2 = math.sin(2.0 * math.pi * base_f2 * t) * 0.25 * lfo2
        s3 = math.sin(2.0 * math.pi * base_f3 * t) * 0.12
        
        # Subtle air circulation rumble
        rumble = (random.random() * 2.0 - 1.0) * 0.04
        
        val = (s1 + s2 + s3 + rumble) * 0.65
        samples.append(val)
    write_wav(path, samples)

if __name__ == "__main__":
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "assets", "audio"))
    sfx_dir = os.path.join(base_dir, "sfx")
    amb_dir = os.path.join(base_dir, "ambient")
    
    generate_grav_shift(os.path.join(sfx_dir, "sfx_grav_shift.wav"))
    generate_laser_shoot(os.path.join(sfx_dir, "sfx_laser_shoot.wav"))
    generate_hit(os.path.join(sfx_dir, "sfx_hit.wav"))
    generate_pickup(os.path.join(sfx_dir, "sfx_pickup.wav"))
    generate_ui_click(os.path.join(sfx_dir, "sfx_ui_click.wav"))
    generate_door_open(os.path.join(sfx_dir, "sfx_door_open.wav"))
    generate_ambient_drone(os.path.join(amb_dir, "ambient_station_drone.wav"))
    print("All VOIDSHIFT audio assets successfully generated!")
