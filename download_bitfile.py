from pynq import PL
from pynq import Overlay

ol = Overlay("zcu104_pl_ddr_test.bit")
ol.download()
print("===================================")
print("IP list:")
for i in ol.ip_dict:
    print(i)

print("===================================")
print("Downloaded?:")
print(ol.is_loaded())