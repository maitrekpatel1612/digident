import os
import platform
import subprocess
import time
import logging
import socket

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class WiFiHotspot:
    def __init__(self, ssid="Digident", password="digident123"):
        self.ssid = ssid
        self.password = password
        self.system = platform.system()
        self.is_active = False
        
    def start(self):
        """Start the WiFi hotspot"""
        if self.is_active:
            logger.info("Hotspot is already active")
            return True
            
        if self.system == "Windows":
            return self._start_windows_hotspot()
        elif self.system == "Linux":
            return self._start_linux_hotspot()
        else:
            logger.error(f"Unsupported operating system: {self.system}")
            return False
            
    def stop(self):
        """Stop the WiFi hotspot"""
        if not self.is_active:
            logger.info("Hotspot is not active")
            return True
            
        if self.system == "Windows":
            return self._stop_windows_hotspot()
        elif self.system == "Linux":
            return self._stop_linux_hotspot()
        else:
            logger.error(f"Unsupported operating system: {self.system}")
            return False
            
    def _start_windows_hotspot(self):
        """Start hotspot on Windows using netsh or Mobile Hotspot feature"""
        try:
            # Check if the hosted network is supported
            check_cmd = ["netsh", "wlan", "show", "drivers"]
            output = subprocess.check_output(check_cmd, text=True)
            
            if "Hosted network supported: Yes" not in output:
                logger.warning("Hosted network is not supported on this device")
                logger.info("Using alternative approach for network connectivity")
                
                # Instead of trying to create a hotspot, just get the current network info
                # and provide instructions for manual connection
                current_ip = self.get_current_network_ip()
                current_ssid = self.get_current_wifi_ssid()
                
                if current_ip:
                    logger.info(f"Current IP address: {current_ip}")
                    if current_ssid:
                        logger.info(f"Current WiFi network: {current_ssid}")
                        logger.info(f"Please connect your mobile device to the WiFi network: {current_ssid}")
                    else:
                        logger.info("Please connect your mobile device to the same network as this computer")
                    
                    # We're not actually creating a hotspot, but we'll return True
                    # so the application continues to run with the current network
                    self.is_active = False
                    return False
                else:
                    logger.error("Could not determine current network IP")
                    return False
                
            # If hosted network is supported, proceed with the original method
            # Stop any existing hotspot
            self._stop_windows_hotspot()
            
            # Set up the hotspot
            setup_cmd = ["netsh", "wlan", "set", "hostednetwork", 
                         f"mode=allow", f"ssid={self.ssid}", f"key={self.password}"]
            subprocess.run(setup_cmd, check=True)
            
            # Start the hotspot
            start_cmd = ["netsh", "wlan", "start", "hostednetwork"]
            subprocess.run(start_cmd, check=True)
            
            logger.info(f"Windows hotspot '{self.ssid}' started successfully")
            self.is_active = True
            return True
            
        except subprocess.CalledProcessError as e:
            logger.error(f"Failed to start Windows hotspot: {e}")
            return False
        except Exception as e:
            logger.error(f"Unexpected error starting Windows hotspot: {e}")
            return False
            
    def _stop_windows_hotspot(self):
        """Stop hotspot on Windows"""
        try:
            # Try to stop the traditional hosted network
            stop_cmd = ["netsh", "wlan", "stop", "hostednetwork"]
            subprocess.run(stop_cmd)
            
            # Also try to stop the Windows 10/11 Mobile Hotspot if it's running
            try:
                subprocess.run([
                    "powershell", "-Command",
                    "$connectionProfile = [Windows.Networking.Connectivity.NetworkInformation,Windows.Networking.Connectivity,ContentType=WindowsRuntime]::GetInternetConnectionProfile(); "
                    "$tetheringManager = [Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager,Windows.Networking.NetworkOperators,ContentType=WindowsRuntime]::CreateFromConnectionProfile($connectionProfile); "
                    "$tetheringManager.StopTetheringAsync();"
                ])
            except Exception as e:
                logger.debug(f"Error stopping Windows Mobile Hotspot (may not be running): {e}")
                
            logger.info("Windows hotspot stopped")
            self.is_active = False
            return True
        except Exception as e:
            logger.error(f"Error stopping Windows hotspot: {e}")
            return False
            
    def _start_linux_hotspot(self):
        """Start hotspot on Linux using create_ap or nmcli"""
        try:
            # Check if create_ap is installed
            if self._command_exists("create_ap"):
                # Kill any existing create_ap processes
                subprocess.run(["pkill", "-f", "create_ap"], stderr=subprocess.DEVNULL)
                
                # Get wireless interface
                wireless_interface = self._get_wireless_interface()
                if not wireless_interface:
                    logger.error("No wireless interface found")
                    return False
                    
                # Get internet interface (for sharing)
                internet_interface = self._get_internet_interface()
                
                # Start the hotspot
                cmd = [
                    "create_ap",
                    "--no-virt",
                    wireless_interface,
                    internet_interface if internet_interface else wireless_interface,
                    self.ssid,
                    self.password
                ]
                
                # Run in background
                subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                time.sleep(5)  # Wait for hotspot to start
                
                logger.info(f"Linux hotspot '{self.ssid}' started with create_ap")
                self.is_active = True
                return True
                
            # Alternative: Use NetworkManager if available
            elif self._command_exists("nmcli"):
                # Create a new WiFi hotspot connection
                subprocess.run([
                    "nmcli", "connection", "add", "type", "wifi", "ifname", self._get_wireless_interface(),
                    "con-name", self.ssid, "autoconnect", "yes", "ssid", self.ssid,
                    "mode", "ap", "ipv4.method", "shared", "wifi-sec.key-mgmt", "wpa-psk",
                    "wifi-sec.psk", self.password
                ])
                
                # Activate the connection
                subprocess.run(["nmcli", "connection", "up", self.ssid])
                
                logger.info(f"Linux hotspot '{self.ssid}' started with NetworkManager")
                self.is_active = True
                return True
                
            else:
                logger.error("Neither create_ap nor NetworkManager is available")
                return False
                
        except Exception as e:
            logger.error(f"Failed to start Linux hotspot: {e}")
            return False
            
    def _stop_linux_hotspot(self):
        """Stop hotspot on Linux"""
        try:
            if self._command_exists("create_ap"):
                subprocess.run(["pkill", "-f", "create_ap"])
            elif self._command_exists("nmcli"):
                subprocess.run(["nmcli", "connection", "down", self.ssid])
                subprocess.run(["nmcli", "connection", "delete", self.ssid])
                
            logger.info("Linux hotspot stopped")
            self.is_active = False
            return True
        except Exception as e:
            logger.error(f"Error stopping Linux hotspot: {e}")
            return False
            
    def _get_wireless_interface(self):
        """Get the name of the wireless interface"""
        if self.system == "Windows":
            try:
                output = subprocess.check_output(["netsh", "wlan", "show", "interfaces"], text=True)
                for line in output.split('\n'):
                    if "Name" in line:
                        return line.split(':')[1].strip()
                return None
            except:
                return None
        else:  # Linux
            try:
                # Try to find wireless interfaces using iw
                if self._command_exists("iw"):
                    output = subprocess.check_output(["iw", "dev"], text=True)
                    for line in output.split('\n'):
                        if "Interface" in line:
                            return line.split('Interface')[1].strip()
                
                # Fallback to checking common wireless interface names
                for iface in ["wlan0", "wlp2s0", "wlp3s0", "wlp4s0"]:
                    if os.path.exists(f"/sys/class/net/{iface}"):
                        return iface
                        
                return None
            except:
                return None
                
    def _get_internet_interface(self):
        """Get the name of the interface with internet connection"""
        if self.system == "Linux":
            try:
                # This is a simplified approach - might need more robust detection
                output = subprocess.check_output(["ip", "route"], text=True)
                for line in output.split('\n'):
                    if "default" in line:
                        parts = line.split()
                        idx = parts.index("dev") if "dev" in parts else -1
                        if idx >= 0 and idx + 1 < len(parts):
                            return parts[idx + 1]
                return None
            except:
                return None
        return None
        
    def _command_exists(self, cmd):
        """Check if a command exists in the system"""
        return subprocess.call(["which", cmd], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) == 0
        
    def get_ip_address(self):
        """Get the IP address of the hotspot"""
        if not self.is_active:
            return None
            
        if self.system == "Windows":
            try:
                output = subprocess.check_output(["ipconfig"], text=True)
                in_section = False
                for line in output.split('\n'):
                    if "Wireless LAN adapter Local Area Connection" in line:
                        in_section = True
                    elif in_section and "IPv4 Address" in line:
                        return line.split(':')[1].strip()
                return "192.168.137.1"  # Default Windows hotspot IP
            except:
                return "192.168.137.1"  # Default as fallback
        else:  # Linux
            try:
                iface = self._get_wireless_interface()
                if not iface:
                    return None
                    
                output = subprocess.check_output(["ip", "addr", "show", iface], text=True)
                for line in output.split('\n'):
                    if "inet " in line:
                        return line.split()[1].split('/')[0]
                return None
            except:
                return None

    def get_current_network_ip(self):
        """Get the IP address of the current network connection as a fallback"""
        try:
            if self.system == "Windows":
                # Try multiple approaches to get a valid IP address
                
                # Approach 1: Use ipconfig to find a suitable IP
                output = subprocess.check_output(["ipconfig"], text=True)
                
                # First, look for any WiFi adapter with an IPv4 address
                wifi_section = False
                wifi_ips = []
                
                for line in output.split('\n'):
                    if "Wireless LAN adapter" in line:
                        wifi_section = True
                    elif "Ethernet adapter" in line or "Tunnel adapter" in line:
                        wifi_section = False
                    
                    if wifi_section and "IPv4 Address" in line:
                        ip = line.split(':')[1].strip()
                        if ip != "169.254." and not ip.startswith("127."):
                            wifi_ips.append(ip)
                
                # If we found WiFi IPs, return the first one
                if wifi_ips:
                    return wifi_ips[0]
                
                # Approach 2: Look for any valid IPv4 address (not link-local or loopback)
                for line in output.split('\n'):
                    if "IPv4 Address" in line:
                        ip = line.split(':')[1].strip()
                        if not ip.startswith("169.254.") and not ip.startswith("127."):
                            return ip
                
                # Approach 3: Use socket to determine IP
                try:
                    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                    s.connect(("8.8.8.8", 80))
                    ip = s.getsockname()[0]
                    s.close()
                    return ip
                except:
                    pass
                    
            elif self.system == "Linux":
                # Get IP address on Linux
                try:
                    # Approach 1: Use hostname -I
                    output = subprocess.check_output(["hostname", "-I"], text=True)
                    ips = output.strip().split()
                    for ip in ips:
                        if ip.startswith("192.168.") or ip.startswith("10.") or ip.startswith("172."):
                            return ip
                    if ips:
                        return ips[0]  # Return the first IP if no private IP found
                except:
                    # Approach 2: Use socket
                    try:
                        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                        s.connect(("8.8.8.8", 80))
                        ip = s.getsockname()[0]
                        s.close()
                        return ip
                    except:
                        pass
                    
            # Fallback to default IP if all else fails
            logger.warning("Could not determine network IP, using default")
            return "192.168.137.1"
            
        except Exception as e:
            logger.error(f"Error getting current network IP: {e}")
            return "192.168.137.1"  # Return default IP as last resort

    def get_current_wifi_ssid(self):
        """Get the SSID of the current WiFi network"""
        if self.system == "Windows":
            try:
                # Get the currently connected WiFi network
                output = subprocess.check_output(["netsh", "wlan", "show", "interfaces"], text=True)
                for line in output.split('\n'):
                    if "SSID" in line and "BSSID" not in line:
                        parts = line.split(':', 1)
                        if len(parts) > 1:
                            return parts[1].strip()
                return None
            except Exception as e:
                logger.error(f"Error getting current WiFi SSID: {e}")
                return None
        elif self.system == "Linux":
            try:
                # Get the currently connected WiFi network on Linux
                output = subprocess.check_output(["iwgetid", "-r"], text=True)
                return output.strip()
            except Exception as e:
                logger.error(f"Error getting current WiFi SSID: {e}")
                return None
        return None

# Example usage
if __name__ == "__main__":
    hotspot = WiFiHotspot()
    if hotspot.start():
        print(f"Hotspot started with SSID: {hotspot.ssid}, Password: {hotspot.password}")
        print(f"IP Address: {hotspot.get_ip_address()}")
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            print("Stopping hotspot...")
            hotspot.stop()
    else:
        print("Failed to start hotspot") 