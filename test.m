%Run this test to confirm everything is working

A = ARAFM();
A = A.load('data/DartPFM.ibw');
A.showImage;
A = A.loadForce('data/DartPFMSpectrum.ibw');
A.showForce