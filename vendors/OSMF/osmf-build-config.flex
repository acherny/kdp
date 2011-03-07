<flex-config>

   <compiler>
      <!-- Turn on generatation of accessible swfs. -->
      <accessible>false</accessible>
      
      <define>
        <name>CONFIG::LOGGING</name>
        <value>false</value>
      </define>

      <define>
        <name>CONFIG::FLASH_10_1</name>
        <value>false</value>
      </define>
      
      <!-- Specifies the locales for internationalization. -->
      <locale>
          <locale-element>en_US</locale-element>
      </locale>
      
      <!-- List of path elements that form the roots of ActionScript class hierarchies. -->
      <source-path>
         <path-element>.</path-element>
      </source-path>
 
      <!-- Allow the source-path to have path-elements which contain other path-elements -->
      <allow-source-path-overlap>false</allow-source-path-overlap>
      
      <!-- Run the AS3 compiler in a mode that detects legal but potentially incorrect -->
      <!-- code.                                                                       -->
      <show-actionscript-warnings>true</show-actionscript-warnings>
      
      <!-- Turn on generation of debuggable swfs.  False by default for mxmlc, -->
      <!-- but true by default for compc. -->
      <!--
      <debug>true</debug>
      -->

      <!-- List of SWC files or directories to compile against but to omit from -->
      <!-- linking.                                                             -->
      <external-library-path>
         <path-element>${flexlib}/libs/air/airglobal.swc</path-element>
      </external-library-path>
      
      <!-- Turn on writing of generated/*.as files to disk. These files are generated by -->
      <!-- the compiler during mxml translation and are helpful with understanding and   -->
      <!-- debugging Flex applications.                                                  -->
      <keep-generated-actionscript>false</keep-generated-actionscript>

      <!-- not set -->
      <!--
      <include-libraries>
         <library>string</library>
      </include-libraries>
      -->
      
      <!-- List of SWC files or directories that contain SWC files. -->
      <library-path>
         <path-element>${flexlib}/libs</path-element>
         <path-element>${flexlib}/locale/{locale}</path-element>
<!--
         <path-element>../Libraries/corelib/corelib.swc</path-element>
         <path-element>../Libraries/crypto/crypto.swc</path-element>
         <path-element>../build/lib/Utils.swc</path-element>
         <path-element>../build/lib/Core.swc</path-element>
-->
         <path-element>${flexlib}/libs/air/servicemonitor.swc</path-element>
         <path-element>${flexlib}/libs/air/airframework.swc</path-element>
      </library-path>
      
      <!-- Enable post-link SWF optimization. -->
      <optimize>true</optimize>

      <!-- Keep the following AS3 metadata in the bytecodes.                                             -->
      <!-- Warning: For the data binding feature in the Flex framework to work properly,                 -->
      <!--          the following metadata must be kept:                                                 -->
      <!--          1. Bindable                                                                          -->
      <!--          2. Managed                                                                           -->
      <!--          3. ChangeEvent                                                                       -->
      <!--          4. NonCommittingChangeEvent                                                          -->
      <!--          5. Transient                                                                         -->
      <keep-as3-metadata>
          <name>Bindable</name>
          <name>Managed</name>
          <name>ChangeEvent</name>
          <name>NonCommittingChangeEvent</name>
          <name>Transient</name>
      </keep-as3-metadata>

      <!-- Turn on reporting of data binding warnings.  For example: Warning: Data binding -->
      <!-- will not be able to detect assignments to "foo".                                -->
      <show-binding-warnings>true</show-binding-warnings>
      
      <!-- Show warnings when deprecated classes, variables and functions are used. -->
      <show-deprecation-warnings>true</show-deprecation-warnings>
 
      <!-- toggle whether warnings generated from unused type selectors are displayed -->
      <show-unused-type-selector-warnings>true</show-unused-type-selector-warnings>

      <!-- Run the AS3 compiler in strict error checking mode. -->
      <strict>true</strict>
      
      <!-- Use the ActionScript 3 class based object model for greater performance and better error reporting. -->
      <!-- In the class based object model most built-in functions are implemented as fixed methods of classes -->
      <!-- (-strict is recommended, but not required, for earlier errors) -->
      <as3>true</as3>
      
      <!-- Use the ECMAScript edition 3 prototype based object model to allow dynamic overriding of prototype -->
      <!-- properties. In the prototype based object model built-in functions are implemented as dynamic      -->
      <!-- properties of prototype objects (-strict is allowed, but may result in compiler errors for         -->
      <!-- references to dynamic properties) -->
      <es>false</es>
      
      <!-- List of CSS or SWC files to apply as a theme. -->
      <!-- not set -->
      <!--
      <theme>
         <filename>string</filename>
         <filename>string</filename>
      </theme>
      -->
      
      <!-- Turns on the display of stack traces for uncaught runtime errors. -->
      <verbose-stacktraces>false</verbose-stacktraces>
      
      <!-- Defines the AS3 file encoding. -->
      <!-- not set -->
      <!--
      <actionscript-file-encoding></actionscript-file-encoding>
      -->
      
      <fonts>

          <!-- Enables FlashType for embedded fonts, which provides greater clarity for small -->
          <!-- fonts.  This setting can be overriden in CSS for specific fonts. -->
          <!-- NOTE: flash-type has been deprecated. Please use advanced-anti-aliasing <flash-type>true</flash-type> -->
          <advanced-anti-aliasing>true</advanced-anti-aliasing>
        
          <!-- The number of embedded font faces that are cached. -->
          <max-cached-fonts>20</max-cached-fonts>
        
          <!-- The number of character glyph outlines to cache for each font face. -->
          <max-glyphs-per-face>1000</max-glyphs-per-face>
       
          <!-- Defines ranges that can be used across multiple font-face declarations. -->
          <!-- See flash-unicode-table.xml for more examples.  -->
          <!-- not set -->
          <!--
          <languages>
              <language-range>
                  <lang>englishRange</lang>
                  <range>U+0020-U+007E</range>
              </language-range>
          </languages>
          -->
       
          <!-- Compiler font manager classes, in policy resolution order-->
          <managers>
              <manager-class>flash.fonts.JREFontManager</manager-class>
              <manager-class>flash.fonts.AFEFontManager</manager-class>
              <manager-class>flash.fonts.BatikFontManager</manager-class>
          </managers>

          <!-- File containing cached system font licensing information produced via 
               java -cp mxmlc.jar flex2.tools.FontSnapshot (fontpath)
               Will default to winFonts.ser on Windows XP and
               macFonts.ser on Mac OS X, so is commented out by default.

          <local-fonts-snapshot>localFonts.ser</local-fonts-snapshot>
          -->
     
      </fonts> 
	   
      <!-- Array.toString() format has changed. -->
      <warn-array-tostring-changes>false</warn-array-tostring-changes>
      
      <!-- Assignment within conditional. -->
      <warn-assignment-within-conditional>true</warn-assignment-within-conditional>
      
      <!-- Possibly invalid Array cast operation. -->
      <warn-bad-array-cast>true</warn-bad-array-cast>
      
      <!-- Non-Boolean value used where a Boolean value was expected. -->
      <warn-bad-bool-assignment>true</warn-bad-bool-assignment>

      <!-- Invalid Date cast operation. -->
      <warn-bad-date-cast>true</warn-bad-date-cast>
      
      <!-- Unknown method. -->
      <warn-bad-es3-type-method>true</warn-bad-es3-type-method>

      <!-- Unknown property. -->
      <warn-bad-es3-type-prop>true</warn-bad-es3-type-prop>

      <!-- Illogical comparison with NaN. Any comparison operation involving NaN will evaluate to false because NaN != NaN. -->
      <warn-bad-nan-comparison>true</warn-bad-nan-comparison>

      <!-- Impossible assignment to null. -->
      <warn-bad-null-assignment>true</warn-bad-null-assignment>

      <!-- Illogical comparison with null. -->
      <warn-bad-null-comparison>true</warn-bad-null-comparison>

      <!-- Illogical comparison with undefined.  Only untyped variables (or variables of type *) can be undefined. -->
      <warn-bad-undefined-comparison>true</warn-bad-undefined-comparison>

      <!-- Boolean() with no arguments returns false in ActionScript 3.0.  Boolean() returned undefined in ActionScript 2.0. -->
      <warn-boolean-constructor-with-no-args>false</warn-boolean-constructor-with-no-args>

      <!-- __resolve is no longer supported. -->
      <warn-changes-in-resolve>false</warn-changes-in-resolve>

      <!-- Class is sealed.  It cannot have members added to it dynamically. -->
      <warn-class-is-sealed>false</warn-class-is-sealed>
 
      <!-- Constant not initialized. -->
      <warn-const-not-initialized>true</warn-const-not-initialized>

      <!-- Function used in new expression returns a value.  Result will be what the -->
      <!-- function returns, rather than a new instance of that function.            -->
      <warn-constructor-returns-value>false</warn-constructor-returns-value>

      <!-- EventHandler was not added as a listener. -->
      <warn-deprecated-event-handler-error>false</warn-deprecated-event-handler-error>

      <!-- Unsupported ActionScript 2.0 function. -->
      <warn-deprecated-function-error>false</warn-deprecated-function-error>

      <!-- Unsupported ActionScript 2.0 property. -->
      <warn-deprecated-property-error>false</warn-deprecated-property-error>

      <!-- More than one argument by the same name. -->
      <warn-duplicate-argument-names>true</warn-duplicate-argument-names>

      <!-- Duplicate variable definition -->
      <warn-duplicate-variable-def>true</warn-duplicate-variable-def>

      <!-- ActionScript 3.0 iterates over an object's properties within a "for x in target" statement in random order. -->
      <warn-for-var-in-changes>false</warn-for-var-in-changes>

      <!-- Importing a package by the same name as the current class will hide that class identifier in this scope. -->
      <warn-import-hides-class>true</warn-import-hides-class>

      <!-- Use of the instanceof operator. -->
      <warn-instance-of-changes>true</warn-instance-of-changes>

      <!-- Internal error in compiler. -->
      <warn-internal-error>true</warn-internal-error>

      <!-- _level is no longer supported. For more information, see the flash.display package. -->
      <warn-level-not-supported>false</warn-level-not-supported>

      <!-- Missing namespace declaration (e.g. variable is not defined to be public, private, etc.). -->
      <warn-missing-namespace-decl>true</warn-missing-namespace-decl>

      <!-- Negative value will become a large positive value when assigned to a uint data type. -->
      <warn-negative-uint-literal>true</warn-negative-uint-literal>

      <!-- Missing constructor. -->
      <warn-no-constructor>false</warn-no-constructor>

      <!-- The super() statement was not called within the constructor. -->
      <warn-no-explicit-super-call-in-constructor>false</warn-no-explicit-super-call-in-constructor>

      <!-- Missing type declaration. -->
      <warn-no-type-decl>true</warn-no-type-decl>
     
      <!-- In ActionScript 3.0, white space is ignored and '' returns 0. Number() returns -->
      <!-- NaN in ActionScript 2.0 when the parameter is '' or contains white space.      -->
      <warn-number-from-string-changes>false</warn-number-from-string-changes>
      
      <!-- Change in scoping for the this keyword.  Class methods extracted from an -->
      <!-- instance of a class will always resolve this back to that instance.  In  -->
      <!-- ActionScript 2.0 this is looked up dynamically based on where the method -->
      <!-- is invoked from.                                                         -->
      <warn-scoping-change-in-this>false</warn-scoping-change-in-this>
      
      <!-- Inefficient use of += on a TextField.-->
      <warn-slow-text-field-addition>true</warn-slow-text-field-addition>
     
      <!-- Possible missing parentheses. -->
      <warn-unlikely-function-value>true</warn-unlikely-function-value>
      
      <!-- Possible usage of the ActionScript 2.0 XML class. -->
      <warn-xml-class-has-changed>false</warn-xml-class-has-changed>
   
   </compiler>

   <!-- compute-digest: writes a digest to the catalog.xml of a library. Use this when the library will be used as a
                        cross-domain rsl.-->
   <!-- compute-digest usage:
   <compute-digest>boolean</compute-digest>
   -->

   <!-- A list of runtime shared library URLs to be loaded before applications start. -->
   <!-- not set -->
   <!--
   <runtime-shared-libraries>
      <url>string</url>
      <url>string</url>
   </runtime-shared-libraries>
   -->
   
   <!-- runtime-shared-library-path: specifies a SWC or directory to link against and an RSL URL to load with optional failover URLs -->
   <runtime-shared-library-path>
      <path-element>libs/framework.swc</path-element>
      <rsl-url>framework_3.0.177608.swz</rsl-url>
      <policy-file-url></policy-file-url>
      <rsl-url>framework_3.0.177608.swf</rsl-url>
      <policy-file-url></policy-file-url>
   </runtime-shared-library-path>
   <!-- static-link-runtime-shared-libraries: statically link the libraries specified by the -runtime-shared-libraries-path option.-->
   <static-link-runtime-shared-libraries>true</static-link-runtime-shared-libraries>
   
   <!-- target-player: specifies the version of the player the application is targeting. 
	               Features requiring a later version will not be compiled into the application. 
                       The minimum value supported is "9.0.0".-->
   <!-- target-player usage:
   -->
   <target-player>10.0.0</target-player>

   <!-- Enables SWFs to access the network. -->
   <use-network>true</use-network>
   
   <!-- Metadata added to SWFs via the SWF Metadata tag. -->
   <metadata>
      <title>OSMF</title>
      <description>OSMF</description>
      <publisher>Wei Zhang</publisher>
      <creator>Wei Zhang</creator>
      <language>EN</language>
   </metadata>

</flex-config>
