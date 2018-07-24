( function _FileProvider_HardDrive_test_ss_( ) {

'use strict';

if( typeof module !== 'undefined' )
{

  require( './aFileProvider.test.s' );

}

//

var _ = _global_.wTools;
var Parent = wTests[ 'Tools/mid/files/fileProvider/Abstract' ];

_.assert( Parent );

//

function onSuiteBegin( test )
{
  this.testRootDirectory = _.dirTempMake( _.pathJoin( __dirname, '../..'  ) );
}

//

function onSuiteEnd()
{
  this.provider.filesDelete( this.testRootDirectory );
}

// --
// define class
// --

var Proto =
{

  name : 'Tools/mid/files/fileProvider/HardDrive',
  abstract : 0,
  silencing : 1,
  enabled : 1,

  // routine : 'readWriteSync',

  onSuiteBegin : onSuiteBegin,
  onSuiteEnd : onSuiteEnd,

  context :
  {
    provider : _.FileProvider.HardDrive(),
    onSuiteBegin : onSuiteBegin,
    testRootDirectory : null,
  },

  tests :
  {
  },

}

//

var Self = new wTestSuite( Proto ).inherit( Parent );
if( typeof module !== 'undefined' && !module.parent )
_.Tester.test( Self.name );

})();