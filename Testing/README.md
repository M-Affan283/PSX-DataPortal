Testing Tool: **Artillery** <br>
Test Tool Justification: <br>Artillery is a powerful and flexible open-source tool for enabling load testing. It is easy to use, with straightforward configuration and the ability to incorporate custom JavaScript logic for complex workflows. It is also easy to set up and lets you create custom tests to mimic real-world behaviour.

----------------------------------------------

### **SETUP**
- **Artillery** supports Windows, Linux and Mac. Before installing Artillery, ensure your system has NodeJS v14 or above installed.
  
      npm version
  
- Next install **Artillery** which may take a few minutes

      npm install -g artillery@latest
  
- To confirm download run the following command

      artillery version
  
- Next perform load testing by running the configured test.

      artillery run load_testing.yml
