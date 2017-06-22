//Gruntfile
module.exports = function(grunt) {

  //Initializing the configuration object
  grunt.initConfig({
    // Task configuration
    uglify: {
      main: {
        files: {
          'dist/main.min.js': 'dist/main.js',
        }
      }
    },
    concat: {
      js: {
        src: ['dist/app.js', 'dist/templates.hbs.js'],
        dest: 'dist/main.js'
      },
    },
    cssmin: {
      minify:{
        files: {
          'dist/styles.min.css': ['app/styles/styles.css']
        }
      }
    },
    handlebars: {
      compile: {
        options: {
          namespace: 'Handlebars.templates',
            processName: function(filePath) {
              return filePath.split('\\').pop().split('/').pop().split('.').shift();
            }
        },
        compilerOptions: {
          knownHelpers: {
          },
          knownHelpersOnly: true
        },
        files: {
          'dist/templates.hbs.js' : 'app/templates/*.handlebars'
        }
      }
    },
    coffee: {
      development: {
        options: {
          bare:false,
          join:true
        },
        files: {
          'dist/app.js': 'app/coffee/*.coffee',
        }
      },
    },
    watch: {
        handlebars: {
            // Watch all .handlebars files from the handlebars directory)
            files: 'app/templates/*.handlebars',
            tasks: ['handlebars'],
            // Reloads the browser
            options: {
              livereload: true
            }
        },
        coffee: {
            // Watch only main.js so that we do not constantly recompile the .js files
            files: 'app/coffee/*.coffee',
            tasks: [ 'coffee' ],
            // Reloads the browser
            options: {
              livereload: true
            }
        }
    }
  });

  // Plugin loading
  grunt.loadNpmTasks('grunt-contrib-cssmin');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-contrib-handlebars');
  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-contrib-concat');
  grunt.loadNpmTasks('grunt-contrib-uglify');

  // Task definition
  grunt.registerTask('default', ['watch']);
};
