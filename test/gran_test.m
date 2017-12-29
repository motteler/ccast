
tday = dnum2iet(datenum('1 aug 2017'));
t0x = dnum2iet(datenum('1 aug 2017, 00:00:03'));
ns = 13;
tf1 = fakeTime(t0x, ns, 1, 0);
tf7 = fakeTime(t0x, ns, 7, 0);

tf1 = reshape(tf1, 34, ns);
tf7 = reshape(tf7, 34, ns);

[t0y, gi] = granule_t0(tf1(1,1), ns);

display(datestr(iet2dnum(t0x)))
display(datestr(iet2dnum(t0y)))

