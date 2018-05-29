(function _FilesRoutines_s_() {

'use strict';

var _ = _global_.wTools;
var FileRecord = _.FileRecord;
var Self = _global_.wTools;

_.assert( FileRecord );

// --
//
// --

/**
 * Turn a *-wildcard style _glob into a regular expression
 * @example
 * var _glob = '* /www/*.js';
 * wTools.regexpForGlob( _glob );
 * // /^.\/[^\/]*\/www\/[^\/]*\.js$/m
 * @param {String} _glob *-wildcard style _glob
 * @returns {RegExp} RegExp that represent passed _glob
 * @throw {Error} If missed argument, or got more than one argumet
 * @throw {Error} If _glob is not string
 * @function regexpForGlob
 * @memberof wTools
 */

function regexpForGlob( _glob )
{

  function strForGlob( _glob )
  {

    var result = '';
    _.assert( arguments.length === 1 );
    _.assert( _.strIs( _glob ) );

    var w = 0;
    _glob.replace( /(\*\*[\/\\]?)|\?|\*/g, function( matched,a,offset,str )
    {

      result += regexpEscape( _glob.substr( w,offset-w ) );
      w = offset + matched.length;

      if( matched === '?' )
      result += '.';
      else if( matched === '*' )
      result += '[^\\\/]*';
      else if( matched.substr( 0,2 ) === '**' )
      result += '.*';
      else _.assert( 0,'unexpected' );

    });

    result += regexpEscape( _glob.substr( w,_glob.length-w ) );
    if( result[ 0 ] !== '^' )
    {
      result = _.strPrependOnce( result,'./' );
      result = _.strPrependOnce( result,'^' );
    }
    result = _.strAppendOnce( result,'$' );

    return result;
  }

  _.assert( arguments.length === 1 );
  _.assert( _.strIs( _glob ) || _.strsAre( _glob ) );

  if( _.strIs( _glob ) )
  _glob = [ _glob ];

  var result = _.entityMap( _glob,( _glob ) => strForGlob( _glob ) );
  result = RegExp( '(' + result.join( ')|(' ) + ')','m' );

  return result;
}

//

function regexpForGlob2( src )
{

  _.assert( _.strIs( src ) || _.strsAre( src ) );
  _.assert( arguments.length === 1 );

  function squareBrackets( src )
  {
    src = _.strInbetweenOf( src, '[', ']' );
    // escape inner []
    src = src.replace( /[\[\]]/g, ( m ) => '\\' + m );
    // replace ! -> ^ at the beginning
    src = src.replace( /^\\!/g, '^' );
    return '[' + src + ']';
  }

  function curlyBrackets( src )
  {
    src = src.replace( /[\}\{]/g, ( m ) => map[ m ] );
    //replace , with | to separate regexps
    src = src.replace( /,+(?![^[|(]*]|\))/g, '|' );
    return src;
  }

  var map =
  {
    0 : '.*', /* doubleAsterix */
    1 : '[^\\\/]*', /* singleAsterix */
    2 : '.', /* questionMark */
    3 : squareBrackets, /* squareBrackets */
    '{' : '(',
    '}' : ')',
  }

  function globToRegexp(  )
  {
    var args = [].slice.call( arguments );
    var i = args.indexOf( args[ 0 ], 1 ) - 1;

    /* i - index of captured group from regexp is equivalent to key from map  */

    if( _.strIs( map[ i ] ) )
    return map[ i ];
    if( _.routineIs( map[ i ] ) )
    return map[ i ]( args[ 0 ] );
  }

  function adjustGlobStr( src )
  {
    _.assert( _.strIs( src ) );

    //espace simple text
    src = src.replace( /[^\*\[\]\{\}\?]+/g, ( m ) => _.regexpEscape( m ) );
    //replace globs with regexps from map
    src = src.replace( /(\*\*\\\/|\*\*)|(\*)|(\?)|(\[.*\])/g, globToRegexp );
    //replace {} -> () and , -> | to make proper regexp
    src = src.replace( /\{.*\}+(?![^[]*\])/g, curlyBrackets );

    return src;
  }

  var result = '';

  if( _.strIs( src ) )
  {
    result = adjustGlobStr( src );
  }
  else
  {
    if( src.length > 1 )
    for( var i = 0; i < src.length; i++ )
    {
      result += `(${adjustGlobStr( src[ i ] )})`;
      if( i + 1 < src.length )
      result += '|'
    }
    else
    result = adjustGlobStr( src[ 0 ] );
  }

  if( !_.strBegins( result, '\\.\/' ) )
  result = _.strPrependOnce( result,'\\.\\/' );

  result = _.strPrependOnce( result,'^' );
  result = _.strAppendOnce( result,'$' );

  // console.log( _glob )

  return RegExp( result,'m' );
}

/**
 * Return o for file red/write. If `filePath is an object, method returns it. Method validate result option
    properties by default parameters from invocation context.
 * @param {string|Object} filePath
 * @param {Object} [o] Object with default o parameters
 * @returns {Object} Result o
 * @private
 * @throws {Error} If arguments is missed
 * @throws {Error} If passed extra arguments
 * @throws {Error} If missed `PathFiile`
 * @method _fileOptionsGet
 * @memberof wTools
 */

function _fileOptionsGet( filePath,o )
{
  var o = o || {};

  if( _.objectIs( filePath ) )
  {
    o = filePath;
  }
  else
  {
    o.filePath = filePath;
  }

  if( !o.filePath )
  throw _.err( '_fileOptionsGet :','expects "o.filePath"' );

  _.assertMapHasOnly( o,this.defaults );
  _.assert( arguments.length === 1 || arguments.length === 2 );

  if( o.sync === undefined )
  o.sync = 1;

  return o;
}

// --
//
// --

/**
 * Returns path/stats associated with file with newest modified time.
 * @example
 * var fs = require('fs');

   var path1 = 'tmp/sample/file1',
   path2 = 'tmp/sample/file2',
   buffer = new Buffer( [ 0x01, 0x02, 0x03, 0x04 ] );

   wTools.fileWrite( { filePath : path1, data : buffer } );
   setTimeout( function()
   {
     wTools.fileWrite( { filePath : path2, data : buffer } );


     var newer = wTools.filesNewer( path1, path2 );
     // 'tmp/sample/file2'
   }, 100);
 * @param {string|File.Stats} dst first file path/stat
 * @param {string|File.Stats} src second file path/stat
 * @returns {string|File.Stats}
 * @throws {Error} if type of one of arguments is not string/file.Stats
 * @method filesNewer
 * @memberof wTools
 */

function filesNewer( dst,src )
{
  var odst = dst;
  var osrc = src;

  _.assert( arguments.length === 2 );

  if( src instanceof File.Stats )
  src = { stat : src };
  else if( _.strIs( src ) )
  src = { stat : File.statSync( src ) };
  else if( !_.objectIs( src ) )
  throw _.err( 'unknown src type' );

  if( dst instanceof File.Stats )
  dst = { stat : dst };
  else if( _.strIs( dst ) )
  dst = { stat : File.statSync( dst ) };
  else if( !_.objectIs( dst ) )
  throw _.err( 'unknown dst type' );

  // Windows does not updating mtime of the file on copy operation - birthtime is needed to get time of last change.   ,
  var timeSrc = _.entityMax( [ src.stat.mtime, src.stat.birthtime ] ).value;
  var timeDst = _.entityMax( [ dst.stat.mtime, dst.stat.birthtime ] ).value;

  // When mtime of the file is changed by fileTimeSet( fs.utime ), there is difference between passed and setted value.
  // if( _.numbersAreEquivalent.call( { EPS : 500 }, timeSrc.getTime(), timeDst.getTime() ) )
  // return null;

  if( timeSrc > timeDst )
  return osrc;
  else if( timeSrc < timeDst )
  return odst;

  return null;
}

  //

/**
 * Returns path/stats associated with file with older modified time.
 * @example
 * var fs = require('fs');

 var path1 = 'tmp/sample/file1',
 path2 = 'tmp/sample/file2',
 buffer = new Buffer( [ 0x01, 0x02, 0x03, 0x04 ] );

 wTools.fileWrite( { filePath : path1, data : buffer } );
 setTimeout( function()
 {
   wTools.fileWrite( { filePath : path2, data : buffer } );

   var newer = wTools.filesOlder( path1, path2 );
   // 'tmp/sample/file1'
 }, 100);
 * @param {string|File.Stats} dst first file path/stat
 * @param {string|File.Stats} src second file path/stat
 * @returns {string|File.Stats}
 * @throws {Error} if type of one of arguments is not string/file.Stats
 * @method filesOlder
 * @memberof wTools
 */

function filesOlder( dst,src )
{

  _.assert( arguments.length === 2 );

  var result = filesNewer( dst,src );

  if( result === dst )
  return src;
  else if( result === src )
  return dst;
  else
  return null;

}

//

  /**
   * Returns spectre of file content.
   * @example
   * var path = '/home/tmp/sample/file1',
     textData1 = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.';

     wTools.fileWrite( { filePath : path, data : textData1 } );
     var spectre = wTools.filesSpectre( path );
     //{
     //   L : 1,
     //   o : 4,
     //   r : 3,
     //   e : 5,
     //   m : 3,
     //   ' ' : 7,
     //   i : 6,
     //   p : 2,
     //   s : 4,
     //   u : 2,
     //   d : 2,
     //   l : 2,
     //   t : 5,
     //   a : 2,
     //   ',' : 1,
     //   c : 3,
     //   n : 2,
     //   g : 1,
     //   '.' : 1,
     //   length : 56
     // }
   * @param {string|wFileRecord} src absolute path or FileRecord instance
   * @returns {Object}
   * @throws {Error} If count of arguments are different from one.
   * @throws {Error} If `src` is not absolute path or FileRecord.
   * @method filesSpectre
   * @memberof wTools
   */

function filesSpectre( src )
{

  _.assert( arguments.length === 1, 'filesSpectre :','expect single argument' );

  src = _.fileProvider.fileRecord( src );
  var read = src.read;

  if( !read )
  read = _.FileProvider.HardDrive().fileRead
  ({
    filePath : src.absolute,
    // silent : 1,
    // returnRead : 1,
  });

  return _.strLattersSpectre( read );
}

//

  /**
   * Compares specters of two files. Returns the rational number between 0 and 1. For the same specters returns 1. If
      specters do not have the same letters, method returns 0.
   * @example
   * var path1 = 'tmp/sample/file1',
     path2 = 'tmp/sample/file2',
     textData1 = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.';

     wTools.fileWrite( { filePath : path1, data : textData1 } );
     wTools.fileWrite( { filePath : path2, data : textData1 } );
     var similarity = wTools.filesSimilarity( path1, path2 ); // 1
   * @param {string} src1 path string 1
   * @param {string} src2 path string 2
   * @param {Object} [o]
   * @param {Function} [onReady]
   * @returns {number}
   * @method filesSimilarity
   * @memberof wTools
   */

function filesSimilarity( o )
{

  _.assert( arguments.length === 1 );
  _.routineOptions( filesSimilarity,o );

  o.src1 = _.fileProvider.fileRecord( o.src1 );
  o.src2 = _.fileProvider.fileRecord( o.src2 );

  // if( !o.src1.latters )
  var latters1 = _.filesSpectre( o.src1 );

  // if( !o.src2.latters )
  var latters2 = _.filesSpectre( o.src2 );

  var result = _.lattersSpectreComparison( latters1,latters2 );

  return result;
}

filesSimilarity.defaults =
{
  src1 : null,
  src2 : null,
}

//

function filesShadow( shadows,owners )
{

  for( var s = 0 ; s < shadows.length ; s++ )
  {
    var shadow = shadows[ s ];
    shadow = _.objectIs( shadow ) ? shadow.relative : shadow;

    for( var o = 0 ; o < owners.length ; o++ )
    {

      var owner = owners[ o ];

      owner = _.objectIs( owner ) ? owner.relative : owner;

      if( _.strBegins( shadow,_.pathPrefix( owner ) ) )
      {
        //logger.log( '?',shadow,'shadowed by',owner );
        shadows.splice( s,1 );
        s -= 1;
        break;
      }

    }

  }

}

//

function fileReport( file )
{
  var report = '';

  var file = _.FileRecord( file );

  var fileTypes = {};

  if( file.stat )
  {
    fileTypes.isFile = file.stat.isFile();
    fileTypes.isDirectory = file.stat.isDirectory();
    fileTypes.isBlockDevice = file.stat.isBlockDevice();
    fileTypes.isCharacterDevice = file.stat.isCharacterDevice();
    fileTypes.isSymbolicLink = file.stat.isSymbolicLink();
    fileTypes.isFIFO = file.stat.isFIFO();
    fileTypes.isSocket = file.stat.isSocket();
  }

  report += _.toStr( file,{ levels : 2, wrap : 0 } );
  report += '\n';
  report += _.toStr( file.stat,{ levels : 2, wrap : 0 } );
  report += '\n';
  report += _.toStr( fileTypes,{ levels : 2, wrap : 0 } );

  return report;
}

// --
// prototype
// --

var Proto =
{

  regexpForGlob : regexpForGlob,
  regexpForGlob2 : regexpForGlob2,


  _fileOptionsGet : _fileOptionsGet,

  filesNewer : filesNewer,
  filesOlder : filesOlder,

  filesSpectre : filesSpectre,
  filesSimilarity : filesSimilarity,

  // filesAreUpToDate : filesAreUpToDate,

  filesShadow : filesShadow,

  fileReport : fileReport,

  // fileStatIs : fileStatIs,

}

_.mapExtend( Self,Proto );

// --
// export
// --

if( typeof module !== 'undefined' )
if( _global_._UsingWtoolsPrivately_ )
delete require.cache[ module.id ];

if( typeof module !== 'undefined' && module !== null )
module[ 'exports' ] = Self;

})();