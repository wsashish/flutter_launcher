import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:call_log/call_log.dart';

class PhonePage extends StatefulWidget {
  @override
  _PhonePageState createState() => _PhonePageState();
}

class _PhonePageState extends State<PhonePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Contact> contacts = [];
  List<CallLogEntry> recentCalls = [];
  bool isLoading = true;
  bool showDialPad = false;
  String phoneNumber = '';
  List<Contact> _allContacts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getContacts();
    _getRecentCalls();
  }

  Future<void> _getRecentCalls() async {
    final status = await Permission.phone.request();
    
    if (status.isGranted) {
      try {
        final Iterable<CallLogEntry> entries = await CallLog.get();
        setState(() {
          recentCalls = entries.toList();
        });
      } catch (e) {
        print('Error loading call log: $e');
      }
    }
  }

  Future<void> _getContacts() async {
    final status = await Permission.contacts.request();
    
    if (status.isGranted) {
      try {
        final contactsList = await ContactsService.getContacts();
        setState(() {
          _allContacts = contactsList.toList();
          contacts = _allContacts;
          isLoading = false;
        });
      } catch (e) {
        print('Error loading contacts: $e');
        setState(() {
          isLoading = false;
        });
      }
    } else {
      print('Contacts permission denied');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onNumberTap(String number) {
    setState(() {
      phoneNumber += number;
    });
  }

  List<Contact> getFilteredContacts() {
    if (phoneNumber.isEmpty) {
      return [];
    }
    return contacts.where((contact) {
      // Check if any phone number matches
      bool matchesNumber = contact.phones?.any(
        (phone) => phone.value?.contains(phoneNumber) ?? false
      ) ?? false;
      
      // Check if name matches (optional)
      bool matchesName = contact.displayName?.toLowerCase()
          .contains(phoneNumber.toLowerCase()) ?? false;
      
      return matchesNumber || matchesName;
    }).toList();
  }

  Widget _buildDialPadOverlay() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Phone number display with backspace
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    phoneNumber,
                    style: TextStyle(fontSize: 32),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (phoneNumber.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.backspace),
                    onPressed: () {
                      setState(() {
                        if (phoneNumber.isNotEmpty) {
                          phoneNumber = phoneNumber.substring(
                              0, phoneNumber.length - 1);
                        }
                      });
                    },
                  ),
              ],
            ),
          ),
          // Suggested contacts
          if (phoneNumber.isNotEmpty) 
            Container(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: getFilteredContacts().length,
                itemBuilder: (context, index) {
                  final contact = getFilteredContacts()[index];
                  return _buildSuggestedContact(contact);
                },
              ),
            ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var row in [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                    ['*', '0', '#']
                  ])
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: row.map((number) => 
                        _buildDialpadButton(number),
                      ).toList(),
                    ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: phoneNumber.isNotEmpty ? () {
                      // Implement call functionality
                    } : null,
                    child: Icon(Icons.call, size: 32),
                    style: ElevatedButton.styleFrom(
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(20),
                      backgroundColor: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialpadButton(String number) {
    return TextButton(
      onPressed: () => _onNumberTap(number),
      child: Text(
        number,
        style: TextStyle(fontSize: 28, color: Colors.black87),
      ),
      style: TextButton.styleFrom(
        padding: EdgeInsets.all(16),
        shape: CircleBorder(),
      ),
    );
  }

  Widget _buildSuggestedContact(Contact contact) {
    final String displayName = contact.displayName ?? 'No Name';
    final String firstLetter = displayName.isNotEmpty 
        ? displayName[0].toUpperCase() 
        : '#';
    final String phoneNumber = contact.phones?.firstOrNull?.value ?? '';
    
    return GestureDetector(
      onTap: () {
        setState(() {
          this.phoneNumber = phoneNumber;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              child: Text(firstLetter),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              radius: 25,
            ),
            SizedBox(height: 4),
            Text(
              displayName,
              style: TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCallsList() {
    if (recentCalls.isEmpty) {
      return Center(child: Text('No recent calls'));
    }

    return ListView.builder(
      itemCount: recentCalls.length,
      itemBuilder: (context, index) {
        final call = recentCalls[index];
        final DateTime callTime = DateTime.fromMillisecondsSinceEpoch(call.timestamp!);
        final String timeAgo = _getTimeAgo(callTime);

        // Get contact name from number
        String displayName = 'Unknown';
        if (call.number != null) {
          final matchingContact = _allContacts.firstWhere(
            (contact) => contact.phones?.any(
              (phone) => phone.value?.contains(call.number!) ?? false
            ) ?? false,
            orElse: () => Contact(),
          );
          displayName = matchingContact.displayName ?? call.number ?? 'Unknown';
        }

        IconData callIcon;
        switch (call.callType) {
          case CallType.incoming:
            callIcon = Icons.call_received;
            break;
          case CallType.outgoing:
            callIcon = Icons.call_made;
            break;
          case CallType.missed:
            callIcon = Icons.call_missed;
            break;
          default:
            callIcon = Icons.call;
        }

        return ListTile(
          leading: Icon(
            callIcon, 
            color: call.callType == CallType.missed ? Colors.red : Colors.green
          ),
          title: Text(
            displayName,
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w500
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (displayName != call.number && call.number != null)
                Text(
                  call.number!,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              Text(
                timeAgo,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          trailing: IconButton(
            icon: Icon(Icons.call),
            color: Colors.green,
            onPressed: () {
              // Implement call functionality
              if (call.number != null) {
                // Make call using call.number
              }
            },
          ),
          onTap: () {
            setState(() {
              showDialPad = true;
              phoneNumber = call.number ?? '';
            });
          },
        );
      },
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildContactsList() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (contacts.isEmpty) {
      return Center(child: Text('No contacts found'));
    }

    return ListView.builder(
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        final String displayName = contact.displayName ?? 'No Name';
        final String firstLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : '#';
        final String phoneNumber = contact.phones?.firstOrNull?.value ?? '';

        return ListTile(
          leading: CircleAvatar(
            child: Text(firstLetter),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          title: Text(displayName),
          subtitle: Text(phoneNumber),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.star_border),
                onPressed: () {
                  // Implement favorite functionality
                },
              ),
              IconButton(
                icon: Icon(Icons.call),
                onPressed: () {
                  // Implement call functionality
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (showDialPad) {
          setState(() {
            showDialPad = false;
            phoneNumber = '';
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: showDialPad 
            ? Text('Keypad')
            : TextField(
                decoration: InputDecoration(
                  hintText: 'Search contacts...',
                  hintStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.search, color: Colors.black),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.black54, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.black, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                style: TextStyle(color: Colors.black),
                cursorColor: Colors.black,
                onChanged: (value) {
                  setState(() {
                    if (value.isEmpty) {
                      contacts = _allContacts; // Reset to all contacts when search is empty
                    } else {
                      contacts = _allContacts.where((contact) {
                        final name = contact.displayName?.toLowerCase() ?? '';
                        final number = contact.phones?.firstOrNull?.value ?? '';
                        return name.contains(value.toLowerCase()) || 
                               number.contains(value);
                      }).toList();
                    }
                  });
                },
              ),
          bottom: !showDialPad ? TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Recent'),
              Tab(text: 'Contacts'),
            ],
          ) : null,
        ),
        body: Stack(
          children: [
            if (!showDialPad)
              TabBarView(
                controller: _tabController,
                children: [
                  _buildRecentCallsList(),
                  _buildContactsList(),
                ],
              ),
            if (showDialPad)
              _buildDialPadOverlay(),
          ],
        ),
        floatingActionButton: !showDialPad ? FloatingActionButton(
          onPressed: () {
            setState(() {
              showDialPad = true;
            });
          },
          child: Icon(Icons.dialpad),
        ) : null,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
